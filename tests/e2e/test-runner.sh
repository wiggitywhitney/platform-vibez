#!/bin/bash

# Check for flags
VERBOSE=false
if [[ "$1" == "-h" || "$1" == "--help" ]]; then
    echo "Usage: $0 [-v|--verbose] [-h|--help]"
    echo "  -v, --verbose  Show output for all tests (not just failures)"
    echo "  -h, --help     Show this help message"
    exit 0
elif [[ "$1" == "-v" || "$1" == "--verbose" ]]; then
    VERBOSE=true
    echo "🚀 Running all tests in parallel (verbose mode)..."
else
    echo "🚀 Running all tests in parallel..."
fi

# List of test files
tests=(
    "basic-deployment-test.yaml"
    "validation-tests.yaml"
    "ingress-tests.yaml"
    "autoscaling-tests.yaml"
    "platform-managed-tests.yaml"
    "edge-cases-tests.yaml"
)

# Start all tests in background, capturing output for failed tests
pids=()
log_files=()
for test in "${tests[@]}"; do
    echo "Starting $test..."
    log_file="/tmp/${test%.yaml}-$$.log"
    log_files+=("$log_file")
    chainsaw test --config chainsaw.yaml --test-file "$test" > "$log_file" 2>&1 &
    pids+=($!)
done

# Wait for all tests to complete
echo "⏳ Waiting for all tests to complete..."
failed=0
for i in "${!pids[@]}"; do
    if wait "${pids[$i]}"; then
        echo "✅ ${tests[$i]} - PASSED"
        if [ "$VERBOSE" = true ]; then
            echo "📋 Output from ${tests[$i]}:"
            cat "${log_files[$i]}"
            echo ""
        fi
        rm -f "${log_files[$i]}"
    else
        echo "❌ ${tests[$i]} - FAILED"
        echo "📋 Output from ${tests[$i]}:"
        cat "${log_files[$i]}"
        echo ""
        rm -f "${log_files[$i]}"
        ((failed++))
    fi
done

echo ""
echo "📊 Results: $((${#tests[@]} - failed)) passed, $failed failed"

if [ $failed -gt 0 ]; then
    echo "❌ $failed test(s) failed. See output above for details."
    exit 1
else
    echo "🎉 All tests passed!"
    exit 0
fi 