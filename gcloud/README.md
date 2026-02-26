
# Gcloud emulators on WSL

## WSL network connection

Test WSL connection from *PowerShell*:
```powershell
# Check WSL IP
wsl hostname -I

# Test
Test-NetConnection -ComputerName <wsl_ip> -Port 8085
```


## PubSub emulator setup

> [Reference](https://cloud.google.com/pubsub/docs/emulator)

Clone [python-pubsub](https://github.com/googleapis/python-pubsub) repo
```sh
git clone https://github.com/googleapis/python-pubsub.git
```

Start and setup emulator
```sh
cd <SCRIPTS_HOME>/gcloud
./start-emu-pubsub

# Make sure execute:
# > source .../pubsub-envs

cd <python_pubsub_location>/.env/bin
source activate

cd <python_pubsub_location>/samples/snippets
pip install --trusted-host pypi.org --trusted-host files.pythonhosted.org --upgrade --force-reinstall -r requirements.txt

cd <SCRIPTS_HOME>/gcloud
./pubsub-topics -c
```

Publish messages
```sh
cd <python_pubsub_location>/.env/bin
source activate

cd <SCRIPTS_HOME>/gcloud
./pubsub-topics -m '{ "id": "6d8070c1-4589-447c-8a0c-2e8e1d71aa2e" }'
```

Monitor messages
```sh
cd <python_pubsub_location>/.env/bin
source activate

cd <SCRIPTS_HOME>/gcloud
./pubsub-topics -w
```


## Spanner WSL setup

> [Reference](https://cloud.google.com/spanner/docs/emulator)
> [Spanner in Java](https://cloud.google.com/spanner/docs/getting-started/java)

Clone [java-spanner](https://github.com/googleapis/java-spanner) repo
```sh
git clone https://github.com/googleapis/java-spanner.git
```

Start and setup emulator
```sh
cd <SCRIPTS_HOME>/gcloud
./start-emu-spanner

# Make sure execute:
# > source .../spanner-envs

export SPANNER_INSTANCE=<spanner_instance>
export SPANNER_DATABASE=<spanner_db_name>

# Register emulator
gcloud config configurations create emulator
gcloud config set auth/disable_credentials true
gcloud config set project $SPANNER_PROJECT_ID
gcloud config set api_endpoint_overrides/spanner http://$SPANNER_EMULATOR_HOST/

# Register instance
gcloud spanner instances create $SPANNER_INSTANCE --config=emulator-config --description="Spanner Instance" --nodes=1

cd <java_spanner_location>/samples/snippets

# Omit if JAR is already created
mvn clean package

java -jar target/spanner-snippets/spanner-google-cloud-samples.jar createdatabase $SPANNER_INSTANCE $SPANNER_DATABASE
```
