#!/bin/bash

SCRIPTS_ROOT=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd)
PACKAGE_ROOT=$(dirname "${SCRIPTS_ROOT}")

# Define constants for directories and file paths

INPUT_DIR=${PACKAGE_ROOT}/test/input
ACTUAL_OUTPUT_DIR=${PACKAGE_ROOT}/test/actual_output
EXPECTED_OUTPUT_DIR=${PACKAGE_ROOT}/test/expected_output

echo $INPUT_DIR
echo $PACKAGE_ROOT
# Remove previous outputs
clean_actual_output() {
    rm -rf $ACTUAL_OUTPUT_DIR/*
}

# Check if file exists
file_exists_or_error() {
    local file_path="$1"

    if [ ! -f "$file_path" ]; then
        echo "Error: File '$file_path' does not exist."
        exit 1
    fi
    echo "Test passed!"

}

# Run the docker command with the given parameters
run_docker_test() {
    local additional_args="$1"
    
    docker run \
        -v $INPUT_DIR:/input:ro \
        -v $ACTUAL_OUTPUT_DIR:/output \
        -e ROBOTO_INPUT_DIR=/input \
        -e ROBOTO_OUTPUT_DIR=/output \
        $additional_args \
        rosbag_info
}

# Compare the actual output to the expected output
compare_outputs() {
    local actual_file="$1"
    local expected_file="$2"
    
    diff $ACTUAL_OUTPUT_DIR/$actual_file $EXPECTED_OUTPUT_DIR/$expected_file
    
    if [ $? -eq 0 ]; then
        echo "Test passed!"
    else
        echo "Test failed!"
    fi
}

# Main test execution
main() {
    # Test 1
    echo "Running Test 1: Basic rosbag metadata test"
    clean_actual_output
    run_docker_test ""
    compare_outputs "rosbag_metadata.json" "rosbag_metadata.json"

    # Test 2
    echo "Running Test 2: Test with ROBOTO_PARAM_SPLIT=True"
    clean_actual_output
    run_docker_test "-e ROBOTO_PARAM_SPLIT=True"
    compare_outputs "test.bag.json" "test.bag.json"

    # Test 3
    echo "Running Test 3: Test for .test.bag.json with ROBOTO_PARAM_SPLIT=True"
    clean_actual_output
    run_docker_test "-e ROBOTO_PARAM_SPLIT=True -e ROBOTO_PARAM_HIDDEN=True"
    compare_outputs ".test.bag.json" ".test.bag.json"


    # Test 4
    echo "Running Test 4: Test for new_name.json with ROBOTO_PARAM_FILE_NAME=new_name.json"
    clean_actual_output
    run_docker_test "-e ROBOTO_PARAM_FILE_NAME=new_name.json"
    file_exists_or_error $ACTUAL_OUTPUT_DIR/new_name.json


}

# Run the main test execution
main
clean_actual_output
