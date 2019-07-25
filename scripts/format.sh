#!/usr/bin/env zsh
set -x

dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
project_dir=$(cd "$dir/" 2> /dev/null && pwd -P)

# run swiftformat to format Swift files
swiftformat $project_dir/source --indent 2

# run clang-format to format Objective C files
format=$(brew --prefix llvm)/bin/clang-format

# .h files
for f in $project_dir/HSCameraUtils/source/**/*.h
do
  $format -i $f
done

# .m files
for f in $project_dir/HSCameraUtils/source/**/*.m
do
  $format -i $f
done

set +x
