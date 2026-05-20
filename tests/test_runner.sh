#!/bin/sh

script_dir=$(CDPATH="" cd -- "$(dirname -- "$0")" && pwd)
project_dir=$(CDPATH="" cd -- "$script_dir/.." && pwd)

passed=0
failed=0
total=0

assert_eq() {
    total=$((total + 1))
    expected="$1"
    actual="$2"
    label="$3"

    if [ "$expected" = "$actual" ]; then
        passed=$((passed + 1))
        printf "  PASS: %s\n" "$label"
    else
        failed=$((failed + 1))
        printf "  FAIL: %s\n" "$label"
        printf "    expected: %s\n" "$expected"
        printf "    actual:   %s\n" "$actual"
    fi
}

assert_contains() {
    total=$((total + 1))
    needle="$1"
    haystack="$2"
    label="$3"

    case "$haystack" in
        *"$needle"*)
            passed=$((passed + 1))
            printf "  PASS: %s\n" "$label"
            ;;
        *)
            failed=$((failed + 1))
            printf "  FAIL: %s\n" "$label"
            printf "    expected to contain: %s\n" "$needle"
            printf "    actual: %s\n" "$haystack"
            ;;
    esac
}

assert_file_exists() {
    total=$((total + 1))
    path="$1"
    label="$2"

    if [ -f "$path" ]; then
        passed=$((passed + 1))
        printf "  PASS: %s\n" "$label"
    else
        failed=$((failed + 1))
        printf "  FAIL: %s\n" "$label"
        printf "    file not found: %s\n" "$path"
    fi
}

run_test_file() {
    test_file="$1"
    test_name=$(basename "$test_file" .sh)
    printf "\n== %s ==\n" "$test_name"

    saved_total=$total
    saved_passed=$passed
    saved_failed=$failed

    . "$test_file"

    for func in $(grep '^test_' "$test_file" | sed 's/().*//' | sort -u); do
        $func
    done

    file_total=$((total - saved_total))
    file_passed=$((passed - saved_passed))
    file_failed=$((failed - saved_failed))
    if [ "$file_total" -eq 0 ]; then
        printf "  (no tests found)\n"
    fi
}

for test_file in "$script_dir"/test_*.sh; do
    [ "$(basename "$test_file")" = "test_runner.sh" ] && continue
    run_test_file "$test_file"
done

printf "\n== Results ==\n"
printf "  %d passed, %d failed, %d total\n" "$passed" "$failed" "$total"

[ "$failed" -eq 0 ] && exit 0 || exit 1
