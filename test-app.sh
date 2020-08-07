#!/usr/bin/env bash

# exit when any command fails
set -e

framework="$1"
issuer="https://dev-133320.okta.com/oauth2/default"
clientId="0oa50oyo7l3H4EjO9357"

# build and package this project
rm -f *.tgz
npm run build
npm pack

# create directory to store created apps
mkdir -p apps
cd apps

# install snapshot version of Okta Auth JS SDK
if [ ! -d ../../okta-auth-js ]; then
  cd ../..
  git clone -b dev-4.0 https://github.com/okta/okta-auth-js.git
  cd okta-auth-js && yarn
  cd dist && npm link
else
  cd ../../okta-auth-js/dist && npm link
fi
# install snapshot version of Okta Angular SDK
if [ ! -d ../../okta-oidc-js ]; then
  cd ../..
  git clone -b ag-angular-auth-instance-OKTA-283293 https://github.com/okta/okta-oidc-js.git
  cd okta-oidc-js && yarn install
  cd packages/okta-angular && npm link @okta/okta-auth-js
  yarn && cd dist && npm link
else
  cd ../../okta-oidc-js/packages/okta-angular/dist && npm link
fi

cd ../../../../schematics/apps

if [ $framework == "angular" ] || [ $framework == "a" ]
then
  ng new angular-app --routing --style css --strict
  cd angular-app
  npm install -D ../../oktadev*.tgz
  schematics @oktadev/schematics:add-auth --issuer=$issuer --clientId=$clientId
  npm link @okta/okta-angular
  ng test --watch=false && ng e2e
elif [ $framework == "react-ts" ] || [ $framework == "rts" ]
then
  npx create-react-app react-app-ts --template typescript
  cd react-app-ts
  npm install -D ../../oktadev*.tgz
  schematics @oktadev/schematics:add-auth --issuer=$issuer --clientId=$clientId
  npm link @okta/okta-auth-js
  CI=true npm test
elif [ $framework == "react" ] || [ $framework == "r" ]
then
  npx create-react-app react-app
  cd react-app
  npm install -D ../../oktadev*.tgz
  schematics @oktadev/schematics:add-auth --issuer=$issuer --clientId=$clientId
  npm link @okta/okta-auth-js
  CI=true npm test
elif [ $framework == "vue-ts" ] || [ $framework == "vts" ]
then
  config=$(cat <<EOF
{
  "useConfigFiles": true,
  "plugins": {
    "@vue/cli-plugin-babel": {},
    "@vue/cli-plugin-typescript": {
      "classComponent": true,
      "useTsWithBabel": true
    },
    "@vue/cli-plugin-router": {
      "historyMode": true
    },
    "@vue/cli-plugin-eslint": {
      "config": "base",
      "lintOn": [
        "save"
      ]
    },
    "@vue/cli-plugin-unit-mocha": {},
    "@vue/cli-plugin-e2e-cypress": {}
  }
}
EOF
)
  vue create vue-app-ts -i "$config"
  cd vue-app-ts
  npm install -D ../../oktadev*.tgz
  schematics @oktadev/schematics:add-auth --issuer=$issuer --clientId=$clientId
  npm link @okta/okta-auth-js
  npm run test:unit
elif [ $framework == "vue" ] || [ $framework == "v" ]
then
  config=$(cat <<EOF
{
  "useConfigFiles": true,
  "plugins": {
    "@vue/cli-plugin-babel": {},
    "@vue/cli-plugin-router": {
      "historyMode": true
    },
    "@vue/cli-plugin-eslint": {
      "config": "base",
      "lintOn": [
        "save"
      ]
    },
    "@vue/cli-plugin-unit-jest": {}
  }
}
EOF
)
  vue create vue-app -i "$config"
  cd vue-app
  npm install -D ../../oktadev*.tgz
  schematics @oktadev/schematics:add-auth --issuer=$issuer --clientId=$clientId
  npm link @okta/okta-auth-js
  npm run test:unit
elif [ $framework == "ionic" ] || [ $framework == "i" ]
then
  ionic start ionic-cordova tabs --type angular --cordova --no-interactive
  cd ionic-cordova
  npm install -D ../../oktadev*.tgz
  schematics @oktadev/schematics:add-auth --issuer=$issuer --clientId=$clientId
  npm link @okta/okta-auth-js
  npm run build && ng test --watch=false
elif [ $framework == "ionic-capacitor" ] || [ $framework == "icap" ]
then
  ionic start ionic-capacitor tabs --type angular --capacitor --no-interactive
  cd ionic-capacitor
  npm install -D ../../oktadev*.tgz
  schematics @oktadev/schematics:add-auth --issuer=$issuer --clientId=$clientId --platform=capacitor
  npm link @okta/okta-auth-js
  npm run build && ng test --watch=false
elif [ $framework == "react-native" ] || [ $framework == "rn" ]
then
  react-native init SecureApp
  cd SecureApp
  npm install -D ../../oktadev*.tgz
  schematics @oktadev/schematics:add-auth --issuer=$issuer --clientId=$clientId
  npm link @okta/okta-auth-js
  # npm test -- -u
elif [ $framework == "express" ] || [ $framework == "e" ]
then
  mkdir express-app && cd express-app
  npx express-generator --view=pug
  npm i
  npm install -D ../../oktadev*.tgz
  schematics @oktadev/schematics:add-auth --issuer=$issuer --clientId=$clientId --clientSecret='may the auth be with you'
  npm link @okta/okta-auth-js
  # npm test -- -u
else
  echo "No '${framework}' framework found!"
fi
