#!/bin/sh

printUsage() {
    bold=$(tput bold)
    normal=$(tput sgr0)
    echo "

    ${bold}BoilerPlate Generator 0.1${normal}

    ${bold}---- Required parameters ----${normal}

     -g <groupId>
     -a <artifactId>
     -s <serviceName>

    ${bold}---- Optional parameters ----${normal}

     -d <true | false>  ( Database enabled, default false )
     -j <pathToJsonFile>


    ${bold}---- Property Explanation ----${normal}

    ${bold}[ -j ]${normal}

    JSON domain model file property should point to a file containing a JSON payload that
    represents some domain object such as a Person. If a valid JSON model is provided,
    a CRUD REST based API will be generated using the JSON model.

    If no JSON model is provided. A CRUD REST API based on the following domain model will
    be provided instead. Code that maps from Request/Response to domain model will also be generated.

    {
      \"id\": <long type>,
      \"externalId\": <UUID type>,
      \"data\": <String type>
    }

    ${bold}[ -d ]${normal}

    With database property toggle sets up all boilerplate code to connect to a
    postgres database if enabled including:

    * Outgoing port interface
    * Interface implementation with result mappers and crud operations
    * Schema migration code including tables and schema
    * Hikkari connection pool and configuration properties

    ${bold}NOTE!${normal}

    If a JSON model file is provided through the ${bold}-j${normal} property,
    database code will generate crud operations based on the JSON model. If no
    JSON definition file is provided, the application will generate code for the
    following model

    {
      \"id\": <long type>,
      \"externalId\": <UUID type>,
      \"createdAt\": <LocalDateTime type>,
      \"data\": <String type>
    }

    ${bold}---- Example usage ----${normal}


    Generate service with database and a specific model

    ./generate-project.sh -g se.edinjakupovic \\
                       -a cool-service \\
                       -s cool-serviceName \\
                       -d true \\
                       -j ./employee.json

    Generate a service with a default model and no database

    ./generate-project.sh -g se.edinjakupovic \\
                       -a cool-service \\
                       -s cool-serviceName
    "
}

groupId=""
artifactId=""
serviceName=""
withDatabase="false"
domainJsonDefinitionFile=""

while getopts g:a:s:d:j:h o; do
  case $o in
    (g) groupId=$OPTARG;;
    (a) artifactId=$OPTARG;;
    (s) serviceName=$OPTARG;;
    (d) withDatabase=$OPTARG;;
    (j) domainJsonDefinitionFile=$OPTARG;;
    (h) printUsage;;
    (*) echo "Unrecognized argument ${OPTARG}"
  esac
done

if [ -z "$groupId" ] ; then
        echo 'Missing required argument for groupId -g' >&2
        exit 1
fi

if [ -z "$artifactId" ] ; then
        echo 'Missing required argument for artifactId -a' >&2
        exit 1
fi

if [ -z "$serviceName" ] ; then
        echo 'Missing required argument for serviceName -s' >&2
        exit 1
fi

if [ -n "$domainJsonDefinitionFile" ] && ! [ -e "$domainJsonDefinitionFile" ] ; then
        echo "Could not find file for domain definition given path: ${domainJsonDefinitionFile}"
        exit 1
fi

if [ -n "$withDatabase" ] && [ "$withDatabase" != "true" ] && [ "$withDatabase" != "false" ] ; then
    echo "Expected either \"true\" or \"false\" for property withDatabase, got [${withDatabase}]"
    exit 1
fi

if [ -n "$domainJsonDefinitionFile" ] ; then
  cp "${domainJsonDefinitionFile}" code-generation/ || (echo "failed to copy jsonDefinition" && exit 1)
fi

cd code-generation || (echo "Unable to navigate to code-gen folder" && exit 1)

javac BoilerPlateGenerator.java

java BoilerPlateGenerator \
     groupId="${groupId}" \
     artifactId="${artifactId}" \
     serviceName="${serviceName}" \
     withDatabase="${withDatabase}" \
     domainJsonDefinitionFile="${domainJsonDefinitionFile}"

rm ./*.class

cd ..
rm -r code-generation

