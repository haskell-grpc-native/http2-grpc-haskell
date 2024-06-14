# This script allows to release all packages.
# a list of to-be-released package is located `scripts/data/release` .

orig=`pwd`
trap "cd ${orig}" EXIT

for project in `cat scripts/data/release`; do
  echo "${project}"
  cd "${orig}/${project}"
  stack build
  stack upload .
done;

