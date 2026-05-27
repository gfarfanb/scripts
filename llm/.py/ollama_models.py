#!/usr/bin/env python3

from os.path import isfile
from os import environ

import sys
import sqlite3
import argparse
import json
import requests
import re
import logging

if sys.platform == 'win32':
    from progressbar import ProgressBar
else:
    from progressbar2 import ProgressBar

sys.path.append(environ['PYLIBSPATH'])
import env_vars # pyright: ignore[reportMissingImports]

ollama_host = env_vars.env_value('OLLAMA_SERVER')
ollama_models_db = env_vars.env_value('LLM_MODELS_DB_FILE')
opencode_config_file = env_vars.env_value('OPENCODE_CONFIG_FILE')
pi_config_file = env_vars.env_value('PI_CONFIG_FILE')

logger = logging.getLogger()

hub_ollama_local = 'Ollama Local'

models_templates_hubs_view ="""
    SELECT om.name,
            ot.template,
            om.model,
            om.parameters,
            om.organization,
            om.quantization,
            om.basename,
            h.name AS hub_name,
            h.base_url,
            h.api_key
        FROM ollama_models om
            JOIN ollama_templates ot
                ON om.template_id = ot.id
            JOIN hubs h
                ON ot.hub_id = h.id
"""

models_templates_hubs_where_filter = """
    AND om.deleted = 0
    AND ot.deleted = 0
    AND h.deleted = 0
"""

models_pull_query ="""
    {view}
        WHERE om.pull = 'LOCAL'
            {view_filter}
""".format(view=models_templates_hubs_view,
           view_filter=models_templates_hubs_where_filter)

models_agents_query = """
    {view}
            JOIN ollama_models_agents oma
                ON om.id = oma.model_id
            JOIN agents a
                ON oma.agent_id = a.id
        WHERE a.name = '{agent}'
            AND om.pull in ('LOCAL', 'CLOUD')
            AND oma.included = 1
            {view_filter}
            AND oma.deleted = 0
            AND a.deleted = 0
""".format(view=models_templates_hubs_view,
           view_filter=models_templates_hubs_where_filter,
           agent='{agent}')


def pull_models():
    model_defs = __get_model_defs()

    for model_def in model_defs:
        model = model_def['model_tag']
        payload = { 'model': model }
        json_payload = json.dumps(payload)

        logger.info("Pulling model [{model}]".format(model=model))

        session = requests.Session()
        with session.post("{host}/api/pull".format(host=ollama_host),
                          data=json_payload,
                          stream=True) as response:
            progress_bars = dict()
            last_status = None

            for response_line in response.iter_lines():
                if response_line:
                    last_status = __process_status(last_status=last_status,
                                                   progress_bars=progress_bars,
                                                   model=model,
                                                   response_line=response_line)

        if response.status_code == 200:
            logger.info("Model [{model}] is up to date".format(model=model))
        else:
            logger.error("Unable to update model [{model}] - {error}".format(
                model=model,
                error=response.json()['error']))


def __process_status(last_status, progress_bars: dict[str, ProgressBar], model, response_line):
    response_status = json.loads(response_line.decode("utf-8"))
    status = __get_or_default(response_status, 'status', 'ref')
    total = __get_or_default(response_status, 'total')

    if status != last_status:
        if progress_bars.get(last_status):
            progress_bars.get(last_status).finish()

        sha256 = __get_or_default(response_status, 'digest')

        if sha256:
            logger.info("[{model}] - pulling {sha256}".format(model=model,
                                                              sha256=sha256))
        else:
            logger.info("[{model}] - {status}".format(model=model,
                                                      status=status))

    if not progress_bars.get(status) and total:
        progress_bars[status] = ProgressBar(max_value=total)

    if progress_bars.get(status):
        completed = __get_or_default(response_status, 'completed')

        if completed:
            progress_bars.get(status).update(completed)

    return status


def cleanup_models():
    model_defs = __get_model_defs()
    required_models = [ d['model_tag'] for d in model_defs ]
    response = requests.get("{host}/api/tags".format(host=ollama_host))

    for pulled_model in response.json()['models']:
        model_name = pulled_model['model']

        if not model_name in required_models:
            payload = { 'model': model_name }
            json_payload = json.dumps(payload)

            response = requests.delete("{host}/api/delete".format(host=ollama_host), data=json_payload)

            if response.status_code == 200:
                logger.info("Model [{model}] was removed".format(model=model_name))
            else:
                logger.error("Unable to remove model [{model}] - {error}".format(
                    model=model_name,
                    error=response.json()['error']))


def __get_model_defs(agent_name=None):
    query = models_pull_query if agent_name is None else models_agents_query.format(agent=agent_name) 
    conn = sqlite3.connect(ollama_models_db)
    cursor = conn.cursor()
    cursor.execute(query)
    rows = cursor.fetchall()
    conn.close()

    model_defs = []
    for row in rows:
        name, template, model, parameters, organization, quantization, basename, hub_name, base_url, api_key = row

        model_def = {
            'name': name,
            'template': template,
            'model': model,
            'parameters': 'latest' if parameters is None else parameters,
            'organization': organization,
            'quantization': 'latest' if quantization is None else quantization,
            'basename': basename,
            'hub_name': hub_name,
            'base_url': base_url,
            'api_key': api_key
        }

        __expand_model(model_def)
        model_defs.append(model_def)

    return model_defs


def __expand_model(model_def):
    model_tag = model_def['template'].format_map(model_def)

    if model_def['basename']:
        model_name = "{name} ({model})".format(name=model_def['name'], model=model_def['basename'])
    else:
        model_name = "{name} ({model})".format(name=model_def['name'], model=model_tag)

    model_def['show_name'] = model_name
    model_def['model_tag'] = model_tag


def sync_opencode():
    if not isfile(opencode_config_file):
        is_create = True
        data = {
            '$schema': 'https://opencode.ai/config.json',
            'provider': {}
        }
    else:
        is_create = False
        with open(opencode_config_file, 'r') as f:
            data = json.load(f)

    model_defs = __get_model_defs(agent_name='OpenCode')
    models_config_by_hub = {}
    provider_by_hub = {}

    for model_def in model_defs:
        hub = model_def['hub_name']
        model = model_def['model_tag']
        provider = provider_by_hub.get(hub)

        if provider is None:
            provider = {
                'id': re.sub(r'[^a-z0-9]', '_', hub.lower()).strip('_'),
                'name': hub,
                'base_url': model_def['base_url'],
                'api_key': model_def['api_key']
            }
            provider_by_hub[hub] = provider

        try:
            models_config = models_config_by_hub.get(hub, {})

            model_base = {
                '_launch': True,
                'name': model_def['show_name']
            }
            models_config[model] = { **model_base, **__get_opencode_spec(model_def)}

            models_config_by_hub[hub] = models_config

            logger.info("Model [{model}] added to OpenCode configuration".format(model=model))
        except KeyError as err:
            logger.debug("No OpenCode configuration defined for model [{model}] - {msg}".format(
                model=model,
                msg=err.args[0]))

    for hub, provider in provider_by_hub.items():
        models_config = models_config_by_hub.get(hub)

        data['provider'][provider['id']] = {
            'name': provider['name'],
            'npm': '@ai-sdk/openai-compatible',
            'options': {
                'baseURL': provider['base_url'],
                'apiKey': provider['api_key']
            },
            'models': models_config
        }

    with open(opencode_config_file, 'w') as f:
        json.dump(data, f, indent=2)

    if is_create:
        logger.info("Created file {file}".format(file=opencode_config_file))
    else:
        logger.info("Updated file {file}".format(file=opencode_config_file))


def __get_opencode_spec(model_def):
    hub = model_def['hub_name']
    model = model_def['model_tag']

    if hub != hub_ollama_local:
        opencode_spec = {
            'limit': {
                'context': 0,
                'output': 0
            }
        }

        model_spec = """
            Model
              name             {name}
              context length   {contextLength}""".format(
                name=model,
                contextLength=0)
        logger.info(model_spec)

        return opencode_spec

    payload = { 'model': model }
    json_payload = json.dumps(payload)
    response = requests.post("{host}/api/show".format(host=ollama_host), data=json_payload)
    model_details = response.json()
    family = model_details['details']['family']
    capabilities = model_details['capabilities']
    context_length = model_details['model_info']["{f}.context_length".format(f=family)]
    embedding_length = model_details['model_info']["{f}.embedding_length".format(f=family)]
    inputs = []

    if 'completion' in capabilities:
        inputs.append('text')

    if 'vision' in capabilities:
        inputs.append('image')
        inputs.append('video')

    opencode_spec = {
        'reasoning': 'thinking' in capabilities,
        'tool_call': 'tools' in capabilities,
        'family': family,
        'modalities': {
            'input': inputs,
            'output': [ 'text' ]
        },
        'limit': {
            'context': context_length,
            'output': 0
        }
    }

    model_spec = """
        Model
          name             {name}
          architecture     {architecture}
          parameters       {parameters}
          context length   {contextLength}
          embedding length {embeddingLength}
          quantization     {quantization}
          capabilities     {capabilities}""".format(
            name=model,
            architecture=model_details['model_info']['general.architecture'],
            parameters=model_details['details']['parameter_size'],
            contextLength=context_length,
            embeddingLength=embedding_length,
            quantization=model_details['details']['quantization_level'],
            capabilities=capabilities)
    logger.info(model_spec)

    return opencode_spec


def sync_pi():
    if not isfile(pi_config_file):
        is_create = True
        data = {
            'providers': {}
        }
    else:
        is_create = False
        with open(pi_config_file, 'r') as f:
            data = json.load(f)

    model_defs = __get_model_defs(agent_name='Pi')
    models_config_by_hub = {}
    provider_by_hub = {}

    for model_def in model_defs:
        hub = model_def['hub_name']
        model = model_def['model_tag']
        provider = provider_by_hub.get(hub)

        if provider is None:
            provider = {
                'id': re.sub(r'[^a-z0-9]', '_', hub.lower()).strip('_'),
                'name': hub,
                'base_url': model_def['base_url'],
                'api_key': model_def['api_key']
            }
            provider_by_hub[hub] = provider

        try:
            models_config = models_config_by_hub.get(hub, [])

            model_base = {
                'id': model,
                'name': model_def['show_name']
            }
            model_base = { **model_base, **__get_pi_spec(model_def)}
            models_config.append(model_base)

            models_config_by_hub[hub] = models_config

            logger.info("Model [{model}] added to Pi configuration".format(model=model))
        except KeyError as err:
            logger.debug("No PI configuration defined for model [{model}] - {msg}".format(
                model=model,
                msg=err.args[0]))

    for hub, provider in provider_by_hub.items():
        models_config = models_config_by_hub.get(hub)

        data['providers'][provider['id']] = {
            'baseUrl': provider['base_url'],
            'api': 'openai-completions',
            'apiKey': provider['api_key'],
            'models': models_config
        }

    with open(pi_config_file, 'w') as f:
        json.dump(data, f, indent=2)

    if is_create:
        logger.info("Created file {file}".format(file=pi_config_file))
    else:
        logger.info("Updated file {file}".format(file=pi_config_file))


def __get_pi_spec(model_def):
    hub = model_def['hub_name']
    model = model_def['model_tag']

    if hub != hub_ollama_local:
        pi_spec = {}

        model_spec = """
            Model
              name             {name}""".format(
                name=model)
        logger.info(model_spec)

        return pi_spec

    payload = { 'model': model }
    json_payload = json.dumps(payload)
    response = requests.post("{host}/api/show".format(host=ollama_host), data=json_payload)
    model_details = response.json()
    family = model_details['details']['family']
    capabilities = model_details['capabilities']
    context_length = model_details['model_info']["{f}.context_length".format(f=family)]
    embedding_length = model_details['model_info']["{f}.embedding_length".format(f=family)]
    inputs = []

    if 'completion' in capabilities:
        inputs.append('text')

    if 'vision' in capabilities:
        inputs.append('image')

    pi_spec = {
        'reasoning': 'thinking' in capabilities,
        'input': inputs,
        'contextWindow': context_length
    }

    model_spec = """
        Model
          name             {name}
          architecture     {architecture}
          parameters       {parameters}
          context length   {contextLength}
          embedding length {embeddingLength}
          quantization     {quantization}
          capabilities     {capabilities}""".format(
            name=model,
            architecture=model_details['model_info']['general.architecture'],
            parameters=model_details['details']['parameter_size'],
            contextLength=context_length,
            embeddingLength=embedding_length,
            quantization=model_details['details']['quantization_level'],
            capabilities=capabilities)
    logger.info(model_spec)

    return pi_spec


def __get_or_default(json, key, default=None):
    try:
        return json[key]
    except KeyError:
        return default


def main():
    try:
        logging.basicConfig(
            format='%(asctime)s %(levelname)s - %(message)s',
            level=env_vars.logging_level())

        parser = argparse.ArgumentParser()
        parser.add_argument('-a', '--agent', action='append', required=False,
                            choices=[ 'opencode', 'pi' ],
                            help='Coding agent to synchronize models; repeat the option to target multiple agents')
        parser.add_argument('-c', '--config', action='store_true',
                            help='Only synchronizes models with specified agent configuration files')
        args = parser.parse_args()

        if not args.config:
            pull_models()
            cleanup_models()

        agents = args.agent if args.agent else []

        for agent in agents:
            match agent:
                case 'opencode':
                    sync_opencode()
                case 'pi':
                    sync_pi()
                case _:
                    raise ValueError("Invalid agent: {agent}".format(agent=agent))
    except BaseException as err:
        logger.error(err.args[0])

    return 0


if __name__ == '__main__':

    exit(main())
