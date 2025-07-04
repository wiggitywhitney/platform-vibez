#!/bin/bash

echo "🚀 Running all tests in parallel..."

# List of test files
tests=(
    "basic-deployment-test.yaml"
    "validation-tests.yaml"
    "ingress-tests.yaml"
    "autoscaling-tests.yaml"
    "platform-managed-tests.yaml"
    "edge-cases-tests.yaml"
)

# Start all tests in background
pids=()
for test in "${tests[@]}"; do
    echo "Starting $test..."
    chainsaw test --config chainsaw.yaml --test-file "$test" > "${test%.yaml}.log" 2>&1 &
    pids+=($!)
done

# Wait for all tests to complete
echo "⏳ Waiting for all tests to complete..."
failed=0
for i in "${!pids[@]}"; do
    if wait "${pids[$i]}"; then
        echo "✅ ${tests[$i]} - PASSED"
    else
        echo "❌ ${tests[$i]} - FAILED"
        ((failed++))
    fi
done

echo ""
echo "📊 Results: $((${#tests[@]} - failed)) passed, $failed failed"

# Show failed test logs
if [ $failed -gt 0 ]; then
    echo ""
    echo "🔍 Failed test logs:"
    for test in "${tests[@]}"; do
        log_file="${test%.yaml}.log"
        if grep -q "FAIL" "$log_file" 2>/dev/null; then
            echo "=== $test ==="
            cat "$log_file"
            echo ""
        fi
    done
    exit 1
else
    echo "🎉 All tests passed!"
    exit 0
fi 