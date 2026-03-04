#!/usr/bin/env python

from os import environ
from os.path import isfile

import argparse
import json
import requests
import logging


logger = logging.getLogger()


def pull_models(host, models_def_file):
    with open(models_def_file, 'r') as f:
        models = json.load(f)

    required_models = set()

    for model in models:
        model_def = models[model]

        if model_def['hub'] == 'ollama':
            model = model_def['ollama']['model']

        elif model_def['hub'] == "huggingface":
            model = "hf.co/{org}/{model}".format(
                org=model_def['huggingface']['organization'],
                model=model_def['huggingface']['model'])

        else:
            raise ValueError("Invalid hub: {n}".format(n=model_def['hub']))

        required_models.add(model)

        payload = { 'model': model, 'stream': False }
        json_payload = json.dumps(payload)

        logger.info("Pulling model [{model}]".format(model=model))

        response = requests.post("{host}/api/pull".format(host=host), data=json_payload)

        if response.status_code == 200:
            logger.info("Model [{model}] is up to date".format(model=model))
        else:
            logger.error("Unable to update model [{model}] - {error}".format(
                model=model,
                error=response.json()['error']))

    cleanup_models(host=host, required_models=required_models)


def cleanup_models(host, required_models):
    response = requests.get("{host}/api/tags".format(host=host))

    for model in response.json()['models']:
        model_name = model['model']

        if not model_name in required_models:
            payload = { 'model': model_name }
            json_payload = json.dumps(payload)

            response = requests.delete("{host}/api/delete".format(host=host), data=json_payload)

            if response.status_code == 200:
                logger.info("Model [{model}] was removed".format(model=model_name))
            else:
                logger.error("Unable to remove model [{model}] - {error}".format(
                    model=model_name,
                    error=response.json()['error']))


def sync_opencode(host, config_file, models_def_file):
    if not isfile(config_file):
        is_create = True
        data = {
            "$schema": "https://opencode.ai/config.json",
            "provider": {}
        }
    else:
        is_create = False
        with open(config_file, 'r') as f:
            data = json.load(f)

    with open(models_def_file, 'r') as f:
        models = json.load(f)

    models_config = {}

    for model in models:
        model_def = models[model]

        if not model_def['hub'] == 'ollama':
            continue
        elif not model_def['ollama']['launch']:
            continue
        else:
            model = model_def['ollama']['model']
            model_name = model_def['name']
            launch = model_def['ollama']['launch']

        model_base = {
            '_launch': launch,
            'name': model_name
        }
        models_config[model] = { **model_base, **model_def['opencode']}

    data['provider']['ollama'] = {
        "models": models_config,
        "name": "Ollama (local)",
        "npm": "@ai-sdk/openai-compatible",
        "options": {
            "baseURL": "{host}/v1".format(host=host)
        }
    }

    with open(config_file, 'w') as f:
        json.dump(data, f, indent=2)

    if is_create:
        logger.info("Created file {file}".format(file=config_file))
    else:
        logger.info("Updated file {file}".format(file=config_file))


def env_value(name, default_value=...):
    try:
        if not environ[name]:
            return default_value
        else:
            return environ[name]
    except KeyError:
        logger.debug("Environment variable {name} not found, default: {default}".format(name=name, default=default_value))
        return default_value


def main():
    try:
        logging.basicConfig(
            format='%(asctime)s %(levelname)s - %(message)s',
            level=logging.getLevelName(
                env_value("LOGGING_LEVEL", "INFO")
                ))

        parser = argparse.ArgumentParser()
        parser.add_argument("-o", "--ollama",
                            help="Ollama host",
                            default=env_value("OLLAMA_SERVER", "http://localhost:11434"))
        parser.add_argument("-m", "--models",
                            help="Models definition file",
                            default=env_value("OLLAMA_MODELS_DEF_FILE"))
        parser.add_argument("-s", "--sync", action="store_true",
                            help="Sync models with OpenCode configuration file")
        parser.add_argument("-c", "--config",
                            help="OpenCode configuration file",
                            default=env_value("OPENCODE_CONFIG_FILE"))
        args = parser.parse_args()

        if args.sync:
            sync_opencode(host=args.ollama,
                          config_file=args.config,
                          models_def_file=args.models)
        else:
            pull_models(host=args.ollama,
                        models_def_file=args.models)
    except ValueError as err:
        logger.error(err.args[0])

    return 0


if __name__ == '__main__':

    exit(main())
