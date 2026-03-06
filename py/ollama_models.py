#!/usr/bin/env python

from os.path import isfile

import argparse
import json
import requests
import logging
import subprocess

import env_vars

ollama_host = env_vars.env_value('OLLAMA_SERVER')
ollama_models_def = env_vars.env_value('OLLAMA_MODELS_DEF_FILE')
opencode_config_file = env_vars.env_value('OPENCODE_CONFIG_FILE')

logger = logging.getLogger()


def pull_models():
    with open(ollama_models_def, 'r') as f:
        models = json.load(f)

    required_models = set()

    for model in models:
        model_def = models[model]

        if is_readonly(model_def):
            continue

        model = get_model(model_def)

        required_models.add(model)

        payload = { 'model': model, 'stream': False }
        json_payload = json.dumps(payload)

        logger.info("Pulling model [{model}]".format(model=model))

        response = requests.post("{host}/api/pull".format(host=ollama_host), data=json_payload)

        if response.status_code == 200:
            logger.info("Model [{model}] is up to date".format(model=model))
        else:
            logger.error("Unable to update model [{model}] - {error}".format(
                model=model,
                error=response.json()['error']))

    cleanup_models(required_models)


def is_readonly(model_def):
    try:
        return model_def['readonly']
    except KeyError:
        return False


def cleanup_models(required_models):
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

    with open(ollama_models_def, 'r') as f:
        models = json.load(f)

    models_config = {}

    for model in models:
        model_def = models[model]

        if not required_opencode(model_def):
            continue

        model = get_model(model_def)

        try:
            model_base = {
                '_launch': True,
                'name': model_def['name']
            }
            models_config[model] = { **model_base, **get_opencode_spec(model=model,
                                                                       hub=model_def['hub'])}

            logger.info("Model [{model}] added to OpenCode configuration".format(model=model))
        except KeyError:
            logger.debug("No OpenCode configuration defined for model [{model}]".format(model=model))

    data['provider']['ollama'] = {
        'models': models_config,
        'name': 'Ollama (local)',
        'npm': '@ai-sdk/openai-compatible',
        'options': {
            'baseURL': "{host}/v1".format(host=ollama_host)
        }
    }

    with open(opencode_config_file, 'w') as f:
        json.dump(data, f, indent=2)

    if is_create:
        logger.info("Created file {file}".format(file=opencode_config_file))
    else:
        logger.info("Updated file {file}".format(file=opencode_config_file))


def required_opencode(model_def):
    if model_def['hub'] == 'ollama':
        try:
            return model_def['ollama']['opencode']
        except KeyError:
            return False
    elif model_def['hub'] == 'huggingface':
        try:
            return model_def['huggingface']['opencode']
        except KeyError:
            return False
    else:
        raise ValueError("Invalid hub: {n}".format(n=model_def['hub']))


def get_model(model_def):
    if model_def['hub'] == 'ollama':
        ollama_def = model_def['ollama']

        if not ollama_def['model']:
            raise ValueError("'model' is empty: {n}".format(n=model_def['hub']))

        model = ollama_def['model']

        if ollama_def['parameters']:
            return "{model}:{parameters}".format(model=model,
                                                 parameters=ollama_def['parameters'])
        else:
            return "{model}:latest".format(model=model)
    elif model_def['hub'] == 'huggingface':
        huggingface_def = model_def['huggingface']

        if not huggingface_def['organization']:
            raise ValueError("'organization' is empty: {n}".format(n=model_def['hub']))
        if not huggingface_def['model']:
            raise ValueError("'model' is empty: {n}".format(n=model_def['hub']))

        model = "hf.co/{org}/{model}".format(
            org=huggingface_def['organization'],
            model=huggingface_def['model'])
        
        if huggingface_def['quantization']:
            return "{model}:{quantization}".format(model=model,
                                                   quantization=huggingface_def['quantization'])
        else:
            return "{model}:latest".format(model=model)
    else:
        raise ValueError("Invalid hub: {n}".format(n=model_def['hub']))


def get_opencode_spec(model, hub):
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
        'cost': {
            'input': 0,
            'output': 0
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


def main():
    try:
        logging.basicConfig(
            format='%(asctime)s %(levelname)s - %(message)s',
            level=env_vars.logging_level())

        parser = argparse.ArgumentParser()
        parser.add_argument('-a', '--agent', default='opencode', required=False,
                            choices=[ 'opencode' ],
                            help='Only synchronizes models with configuration file')
        parser.add_argument('-s', '--sync', action='store_true',
                            help='Only synchronizes models with configuration file')
        args = parser.parse_args()

        match args.agent:
            case 'opencode':
                if args.sync:
                    sync_opencode()
                else:
                    pull_models()
                    sync_opencode()
            case _:
                raise ValueError("Invalid agent: {agent}".format(agent=args.agent))
    except ValueError as err:
        logger.error(err.args[0])

    return 0


if __name__ == '__main__':

    exit(main())
