#!/usr/bin/env python

from os.path import isfile
from os import environ

import sys
import argparse
import json
import requests
import logging

if sys.platform == 'win32':
    from progressbar import ProgressBar
else:
    from progressbar2 import ProgressBar

sys.path.append(environ['PYLIBSPATH'])
import env_vars # pyright: ignore[reportMissingImports]

ollama_host = env_vars.env_value('OLLAMA_SERVER')
ollama_models_def = env_vars.env_value('OLLAMA_MODELS_DEF_FILE')
opencode_config_file = env_vars.env_value('OPENCODE_CONFIG_FILE')
pi_config_file = env_vars.env_value('PI_CONFIG_FILE')

logger = logging.getLogger()


def pull_models():
    model_defs, _ = __get_model_defs(filtered=True)

    for model_def in model_defs:
        model, _ = __get_model(model_def)
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
    _, required_models = __get_model_defs()
    response = requests.get("{host}/api/tags".format(host=ollama_host))

    for model_tag in response.json()['models']:
        model_name = model_tag['model']

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
                

def __get_model_defs(filtered=False):
    with open(ollama_models_def, 'r') as f:
        model_defs = json.load(f)

    filtered_defs = []
    required_models = set()
    hubs = [ 'ollama', 'huggingface' ]

    for model_def in model_defs:
        try:
            if model_def['hub'] not in hubs:
                raise ValueError("Invalid hub for model: {hub} - {model}".format(
                    model=model_def,
                    hub=model_def['hub']))

            not_defined_count = 0
            for hub in hubs:
                try:
                    model_def[hub]
                except KeyError:
                    not_defined_count += 1

            if not_defined_count == len(hubs):
                raise ValueError("No hub definition found in model, expected: {hubs} - {model}".format(
                    model=model_def,
                    hubs=hubs))
            else:
                try:
                    model_def[model_def['hub']]
                except KeyError:
                    raise ValueError("No hub definition found in model: {hub} - {model}".format(
                    model=model_def,
                    hub=model_def['hub']))
        except KeyError as err:
            raise ValueError("Undefined field for model: {n} - {model}".format(
                model=model_def,
                n=err.args[0]))

        if __is_readonly(model_def):
            continue

        model, _ = __get_model(model_def)

        required_models.add(model)
        filtered_defs.append(model_def)

    if filtered:
        return filtered_defs, required_models
    else:
        return model_defs, required_models


def __get_model(model_def):
    if model_def['hub'] == 'ollama':
        ollama_def = model_def['ollama']

        if not __get_or_default(ollama_def, 'model'):
            raise ValueError("'model' is empty: {n}".format(n=model_def['hub']))

        model = ollama_def['model']

        if __get_or_default(ollama_def, 'parameters'):
            model = "{model}:{parameters}".format(model=model,
                                                 parameters=ollama_def['parameters'])
        else:
            model = "{model}:latest".format(model=model)

        basename = __get_ollama_basename(ollama_def)

        if basename:
            model_name = "{name} ({model})".format(name=model_def['name'], model=basename)
        else:
            model_name = "{name} ({model})".format(name=model_def['name'], model=model)

    if model_def['hub'] == 'huggingface':
        huggingface_def = model_def['huggingface']

        if not __get_or_default(huggingface_def, 'organization'):
            raise ValueError("'organization' is empty: {n}".format(n=model_def['hub']))
        if not __get_or_default(huggingface_def, 'model'):
            raise ValueError("'model' is empty: {n}".format(n=model_def['hub']))

        model = "hf.co/{org}/{model}".format(
            org=huggingface_def['organization'],
            model=huggingface_def['model'])

        if __get_or_default(huggingface_def, 'quantization'):
            model = "{model}:{quantization}".format(model=model,
                                                    quantization=huggingface_def['quantization'])
        else:
            model = "{model}:latest".format(model=model)

        model_name = "{name} ({model})".format(name=model_def['name'], model=model)

    return model, model_name


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

    model_defs, _ = __get_model_defs()
    models_config = {}

    for model_def in model_defs:
        model, model_name = __get_model(model_def)

        if not __required_opencode(model_def):
            logger.debug("Model [{model}] not required for OpenCode".format(model=model))
            continue

        try:
            model_base = {
                '_launch': True,
                'name': model_name
            }
            models_config[model] = { **model_base, **__get_opencode_spec(model=model,
                                                                         hub=model_def['hub'])}

            logger.info("Model [{model}] added to OpenCode configuration".format(model=model))
        except KeyError as err:
            logger.debug("No OpenCode configuration defined for model [{model}] - {msg}".format(
                model=model,
                msg=err.args[0]))

    base_url = "{host}/v1".format(host=ollama_host.rstrip('/'))

    data['provider']['ollama'] = {
        'name': 'Ollama (local)',
        'npm': '@ai-sdk/openai-compatible',
        'options': {
            'baseURL': base_url
        },
        'models': models_config
    }

    with open(opencode_config_file, 'w') as f:
        json.dump(data, f, indent=2)

    if is_create:
        logger.info("Created file {file}".format(file=opencode_config_file))
    else:
        logger.info("Updated file {file}".format(file=opencode_config_file))


def __get_opencode_spec(model, hub):
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
          hub              {hub}
          architecture     {architecture}
          parameters       {parameters}
          context length   {contextLength}
          embedding length {embeddingLength}
          quantization     {quantization}
          capabilities     {capabilities}""".format(
            name=model,
            hub=hub,
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

    model_defs, _ = __get_model_defs()
    models_config = []

    for model_def in model_defs:
        model, model_name = __get_model(model_def)

        if not __required_pi(model_def):
            logger.debug("Model [{model}] not required for PI".format(model=model))
            continue

        try:
            model_base = {
                'id': model,
                'name': model_name
            }
            model_base = { **model_base, **__get_pi_spec(model=model,
                                                         hub=model_def['hub'])}
            models_config.append(model_base)

            logger.info("Model [{model}] added to Pi configuration".format(model=model))
        except KeyError as err:
            logger.debug("No PI configuration defined for model [{model}] - {msg}".format(
                model=model,
                msg=err.args[0]))

    base_url = "{host}/v1".format(host=ollama_host.rstrip('/'))

    data['providers']['ollama'] = {
        'baseUrl': base_url,
        'api': 'openai-completions',
        'apiKey': 'ollama',
        'models': models_config
    }

    with open(pi_config_file, 'w') as f:
        json.dump(data, f, indent=2)

    if is_create:
        logger.info("Created file {file}".format(file=pi_config_file))
    else:
        logger.info("Updated file {file}".format(file=pi_config_file))


def __get_pi_spec(model, hub):
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
          hub              {hub}
          architecture     {architecture}
          parameters       {parameters}
          context length   {contextLength}
          embedding length {embeddingLength}
          quantization     {quantization}
          capabilities     {capabilities}""".format(
            name=model,
            hub=hub,
            architecture=model_details['model_info']['general.architecture'],
            parameters=model_details['details']['parameter_size'],
            contextLength=context_length,
            embeddingLength=embedding_length,
            quantization=model_details['details']['quantization_level'],
            capabilities=capabilities)
    logger.info(model_spec)

    return pi_spec


def __get_ollama_basename(ollama_def):
    try:
        return ollama_def['info']['basename']
    except KeyError:
        return None


def __is_readonly(model_def):
    try:
        return model_def['readonly']
    except KeyError:
        return False


def __required_opencode(model_def):
    try:
        return model_def[model_def['hub']]['info']['opencode']
    except KeyError:
        return False


def __required_pi(model_def):
    try:
        return model_def[model_def['hub']]['info']['pi']
    except KeyError:
        return False


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
