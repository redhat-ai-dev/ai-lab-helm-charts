#!/bin/bash

replace() {
    old="$1"
    new="$2"
    input_file="$3"

    # replace single mentions and mentions inside conditionals
    sed -i "s/{{$old}}/{{ $new }}/g" "$input_file"
    sed -i "s/$old/$new/g" "$input_file"    
}

convert() {
    input_file="$1"

    # One to one mappings for all application parameter values
    replace "values\.name" ".Release.Name" "$input_file"
    replace "values\.appContainer" ".Values.application.appContainer" "$input_file"
    replace "values\.appPort" ".Values.application.appPort" "$input_file"

    # One to one mappings for all model parameter values
    replace "values\.vllmSelected" ".Values.model.vllmSelected" "$input_file"
    replace "values\.initContainer" ".Values.model.initContainer" "$input_file"
    replace "values\.modelEndpoint" ".Values.model.modelEndpoint" "$input_file"
    replace "values\.modelName" ".Values.model.modelName" "$input_file"
    replace "values\.modelInitCommand" ".Values.model.modelInitCommand" "$input_file"
    replace "values\.vllmModelServiceContainer" ".Values.model.vllmModelServiceContainer" "$input_file"
    replace "values\.modelServiceContainer" ".Values.model.modelServiceContainer" "$input_file"
    replace "values\.modelServicePort" ".Values.model.modelServicePort" "$input_file"
    replace "values\.modelPath" ".Values.model.modelPath" "$input_file"
    replace "values\.includeModelEndpointSecret" ".Values.model.includeModelEndpointSecret" "$input_file"
    replace "values\.modelEndpointSecretName" ".Values.model.modelEndpointSecretName" "$input_file"
    replace "values\.modelEndpointSecretKey" ".Values.model.modelEndpointSecretKey" "$input_file"
    replace "values\.existingModelServer" ".Values.model.existingModelServer" "$input_file"
    replace "values\.dbRequired" ".Values.model.dbRequired" "$input_file"
    replace "values\.maxModelLength" ".Values.model.maxModelLength" "$input_file"

    # Update if conditions
    sed -i 's/{%- if/{{ if/g' "$input_file"
    sed -i 's/{%- endif %}/{{ end }}/g' "$input_file"

    # Generic update on brackets
    sed -i 's/{%-/{{/g' "$input_file"
    sed -i 's/%}/}}/g' "$input_file"

    # Remove managed-by: kustomize
    sed -i '/managed-by: kustomize/d' "$input_file"

    # Add explicit namespace mention
    awk '
    /  name: {{ .Release.Name }}/ && !namespace_added {
    print $0
    print "  namespace: {{ .Release.Namespace }}"
    namespace_added=1
    next
    }
    { print }
    ' "$input_file" > tmp && mv tmp "$input_file"

    # Update conditionals
    sed -E -i 's/\{\{\ if ([^ ]+) or ([^ ]+) \}\}/{{- if or \1 \2 }}/' "$input_file"
    sed -E -i 's/\{\{\ if ([^ ]+) == nil or not\(([^ ]+)\) \}\}/{{- if or (not \1) (eq \2 nil) }}/' "$input_file"

    # remove blocks related to RAG database - should be supported only for the rag case
    sed -i '/{{ if \.Values\.model\.dbRequired }}/,/{{ end }}/d' "$input_file"

    # add conditional for existing model server for the model-server resources.
    if [[ $input_file == *"model-server"* ]]; then
        sed -i '1i {{ if not .Values.model.existingModelServer }}' "$input_file"
        sed -i '$a {{ end }}' "$input_file"
    fi

    # add pvc resource only for the vllm case.
    if [[ $input_file == *"pvc"* ]]; then
        sed -i '1i {{ if .Values.model.vllmSelected }}' "$input_file"
        sed -i '$a {{ end }}' "$input_file"
    fi
}

convert_all() {
    gitops_templates_dir="$1"
    root_dir="$2"

    echo "Root dir = $root_dir"
    for file in "$gitops_templates_dir"/*.yaml; do
        if [[ -f $file ]]; then
            # Get the relative path to compare
            relFile=$(echo "$file" | sed "s|$root_dir/||")
            # Check if the fetched file is inside the list of included files for the given env
            if [[ $INCLUDE_FILES == *$relFile* ]]; then
                convert "$file"
                cp "$file" "$CHART_PATH"/templates
            else
                echo "Skip $file"
            fi
        fi
    done
}

reset_repo() {
    REPO_DIR="$1"
    ORIGINAL_DIR="$2"

    cd "$REPO_DIR"
    git reset --hard
    cd "$ORIGINAL_DIR"
}

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )" 
ROOT_DIR=$(realpath "$SCRIPT_DIR"/..)

# Fetch the contents of the gitops repo
REPO="${SAMPLE_REPO:-https://github.com/redhat-ai-dev/ai-lab-app}"
BRANCH="${SAMPLE_BRANCH:-main}"

# Create the temp dir to store the gitops repo contents
TEMP_DIR=$SCRIPT_DIR/tmp
mkdir -p "$TEMP_DIR"

# Define gitops, templates and env dirs
GITOPS_TEMPLATES_DIR=$TEMP_DIR/templates/http/base
ENVS_DIR=$SCRIPT_DIR/envs

# Clone the gitops repo and move the content
git clone -b "$BRANCH" "$REPO" "$TEMP_DIR" > /dev/null 2>&1 

for env in "$ENVS_DIR"/*; do
    reset_repo "$TEMP_DIR" "$ROOT_DIR"
    echo "Sourcing env $env"
    if [[ "$env" == *"_base"* ]]; then
        # skipping execution for the base env
        continue
    fi
    source "$env"
    convert_all "$GITOPS_TEMPLATES_DIR" "$ROOT_DIR"
done

# Remove the cloned repo
rm -rf "$TEMP_DIR"