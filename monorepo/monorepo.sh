#!/bin/bash

if [ "$#" -ne 1 ]; then
    echo "Usage: startup.sh <project_name>"
    exit 1
fi

# Create a new directory given as argument and cd into it
mkdir -p $1
cd $1

if [ "$1" == "." ]; then
    var=$(pwd)
    mydir=${var##*/}
else
    mydir=$1
fi

echo "# $mydir" >README.md

# Initialize the git and enforce node version with some info in the readme.md
pnpm init
git init

node_version=$(node -v)
echo "node version: ${node_version:1}" >>README.md
echo -e "node_modules" >.gitignore
echo -e "pnpm-lock.yaml" >>.gitignore

npm pkg set engines.node=">=${node_version:1}"
npm pkg set type="module"

# Code formatting with prettier
pnpm add -D prettier

echo -e '{\n  "semi": false,\n  "singleQuote": true,\n  "trailingComma": "es5",\n  "printWidth": 100,\n  "tabWidth": 2\n}' >.prettierrc.json
echo -e "coverage\nnode_modules\npnpm-lock.yaml\npnpm-workspace.yaml" >>.prettierignore

# VS Code settings
mkdir .vscode
touch .vscode/settings.json

echo -e '{\n  "editor.formatOnSave": true,\n  "editor.defaultFormatter": "esbenp.prettier-vscode"\n}' >.vscode/settings.json

# Linting with eslint
pnpm create @eslint/config

sed -i '' -e '2i\
  "root": true,' .eslintrc.cjs

touch .eslintignore
echo -e "coverage\npublic\ndist\npnpm-lock.yaml\npnpm-workspace.yaml" >>.eslintignore

# Integrate eslint with prettier
pnpm add -D eslint-config-prettier eslint-plugin-prettier
sed -i '' -e '9i\
    "plugin:prettier/recommended",' .eslintrc.cjs

npm pkg set scripts.lint="eslint ."
npm pkg set scripts.lint:fix="eslint . --fix"
npm pkg set scripts.format="prettier --write ."

# Pre-commit hooks with husky and lint-staged
pnpm add -D @commitlint/cli @commitlint/config-conventional
echo -e "export default { extends: ['@commitlint/config-conventional'] };" >commitlint.config.js

pnpm add -D husky lint-staged
npx husky init
echo "pnpm lint-staged" >.husky/pre-commit
echo "npx --no -- commitlint --edit ${1}" >.husky/commit-msg

# Update the package.json file
sed -i '' '32i\
    , "lint-staged": {\
        "**/*.{js,ts,tsx}": [\
        "eslint --fix"],\
        "**/*": "prettier --write --ignore-unknown"\
        }' package.json

# Workspaces with pnpm
touch pnpm-workspace.yaml
echo -e "packages:\n  - 'apps/*'\n  - 'packages/*'" >pnpm-workspace.yaml

# Create apps and packages directories
mkdir apps packages

# Format the code with prettier and lint with eslint
pnpm lint:fix
pnpm format
