#!/bin/bash

# Enhanced Test Runner for Platform Vibez E2E Tests
# Supports organized directory structure and category-specific testing

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
VERBOSE=false
CATEGORY=""
TEST_CATEGORIES=("policies" "application" "integration" "validation")

# Function to print colored output
print_status() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

print_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

# Function to show usage
show_usage() {
    echo "Usage: $0 [OPTIONS] [CATEGORY]"
    echo ""
    echo "Run Platform Vibez E2E tests with organized categories"
    echo ""
    echo "CATEGORIES:"
    echo "  policies      Run platform governance policy tests"
    echo "  application   Run Helm chart application tests"
    echo "  integration   Run full-stack integration tests"
    echo "  validation    Run input validation and edge case tests"
    echo "  (none)        Run all tests in all categories"
    echo ""
    echo "OPTIONS:"
    echo "  -v, --verbose Show output for all tests (not just failures)"
    echo "  -h, --help    Show this help message"
    echo ""
    echo "EXAMPLES:"
    echo "  $0                    # Run all tests"
    echo "  $0 policies           # Run only policy tests"
    echo "  $0 application        # Run only application tests"
    echo "  $0 -v policies        # Run policy tests with verbose output"
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -v|--verbose)
            VERBOSE=true
            shift
            ;;
        -h|--help)
            show_usage
            exit 0
            ;;
        policies|application|integration|validation)
            CATEGORY="$1"
            shift
            ;;
        *)
            echo "Unknown option: $1"
            show_usage
            exit 1
            ;;
    esac
done

# Function to discover test files
discover_tests() {
    local category="$1"
    local test_files=()
    
    if [[ -n "$category" ]]; then
        # Run tests from specific category
        if [[ -d "$category" ]]; then
            while IFS= read -r -d '' file; do
                test_files+=("$file")
            done < <(find "$category" -name "*.yaml" -type f -print0 | sort -z)
        else
            print_error "Category directory '$category' not found"
            return 1
        fi
    else
        # Run all tests from all categories
        for cat in "${TEST_CATEGORIES[@]}"; do
            if [[ -d "$cat" ]]; then
                while IFS= read -r -d '' file; do
                    test_files+=("$file")
                done < <(find "$cat" -name "*.yaml" -type f -print0 | sort -z)
            fi
        done
    fi
    
    printf '%s\n' "${test_files[@]}"
}

# Function to run a single test
run_test() {
    local test_file="$1"
    local log_file="$2"
    
    chainsaw test --config chainsaw.yaml --test-file "$test_file" > "$log_file" 2>&1
    return $?
}

# Main execution
main() {
    print_info "Platform Vibez E2E Test Runner"
    echo "======================================"
    
    # Show what we're running
    if [[ -n "$CATEGORY" ]]; then
        if [[ "$VERBOSE" == true ]]; then
            echo "🚀 Running $CATEGORY tests (verbose mode)..."
        else
            echo "🚀 Running $CATEGORY tests..."
        fi
    else
        if [[ "$VERBOSE" == true ]]; then
            echo "🚀 Running all tests (verbose mode)..."
        else
            echo "🚀 Running all tests..."
        fi
    fi
    
    # Discover test files
    print_info "Discovering test files..."
    tests=()
    while IFS= read -r file; do
        tests+=("$file")
    done < <(discover_tests "$CATEGORY")
    
    if [[ ${#tests[@]} -eq 0 ]]; then
        print_error "No test files found"
        exit 1
    fi
    
    echo "Found ${#tests[@]} test files:"
    for test in "${tests[@]}"; do
        echo "  • $test"
    done
    echo ""
    
    # Start all tests in background
    pids=()
    log_files=()
    
    for test in "${tests[@]}"; do
        test_name=$(basename "$test" .yaml)
        echo "Starting $test..."
        log_file="/tmp/${test_name}-$$.log"
        log_files+=("$log_file")
        
        run_test "$test" "$log_file" &
        pids+=($!)
    done
    
    # Wait for all tests to complete
    echo ""
    echo "⏳ Waiting for all tests to complete..."
    echo ""
    
    failed=0
    passed=0
    
    for i in "${!pids[@]}"; do
        if wait "${pids[$i]}"; then
            print_status "${tests[$i]} - PASSED"
            ((passed++))
            
            if [[ "$VERBOSE" == true ]]; then
                echo "📋 Output from ${tests[$i]}:"
                cat "${log_files[$i]}"
                echo ""
            fi
            rm -f "${log_files[$i]}"
        else
            print_error "${tests[$i]} - FAILED"
            ((failed++))
            
            echo "📋 Output from ${tests[$i]}:"
            cat "${log_files[$i]}"
            echo ""
            rm -f "${log_files[$i]}"
        fi
    done
    
    # Summary
    echo ""
    echo "📊 Test Results Summary"
    echo "======================="
    echo "  Total tests: ${#tests[@]}"
    echo "  Passed: $passed"
    echo "  Failed: $failed"
    echo ""
    
    if [[ $failed -gt 0 ]]; then
        print_error "$failed test(s) failed. See output above for details."
        exit 1
    else
        print_status "All tests passed! 🎉"
        exit 0
    fi
}

# Run main function
main "$@" 