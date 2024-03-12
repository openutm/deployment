# Introduction and objective

In this article you will understand how build the environment files for the OpenUTM system. We are assuming that you will have  The general flow of this document is that you will need a Flight Passport installation running (or any other OAUTH 2.0 server) installation.

- Flight Passport (Authorization server)
- Flight Blender (Backend)
- Flight Spotlight (Frontend - optional)

## Create the Passport Environment file

Use the [template](env.examples/.passport.env.local) to fill in your values. The file should be self-explanatory some notes for some of the variables are below:

- `OIDC_RSA_PRIVATE_KEY`: For this key you can use a command like `openssl genrsa -out oidc.pem 4096` to generate a private key and paste it there.
- `DOMAIN_WHITELIST`: This is used to allow logins from the domains listed (and prohibiting disallowed domains) e.g. `openskies.sh;openutm.net;`
- `ESP_*`: The project uses [anymail](https://anymail.dev/en/stable/) to send transactional emails, you will need to set it up for your domain if you want to enable email verification and other features e.g. reset password via email etc.
- `JWT_ISSUER_DOMAIN`: Use your domain name if using locally, you can use `http://localhost:8000` or something similar this will be used to populate `iss` claim in the token

## Login and change password for Flight Passport

### Login

Go to your Passport URL and then to the `/admin/` endpoint and login using the default credentials as you may have set it on your side e.g. if you are using Docker Compose and the default environment file, it is `admin` / `admin`
![login](images/environment_files_help/step_1_login.jpg)

### Change password

It is recommended that you change the password immediately at this step.

![login](images/environment_files_help/step_1b_change_password.jpg)

### Create Scopes

You will need to create four scopes (two for login / profile information and two for Flight Blender)
![scopes](images/environment_files_help/step_2a_scopes.jpg)

- `openid`
- `profile`
- `blender.read`
- `blender.write`

![scopes_list](images/environment_files_help/step_2b_scopes_list.jpg)

### Create APIs

You will need to create two apis, that define how these scopes will be used in the "application". We will create two APIs one for the login and one for reading and writing data into Flight Blender.
![create_api_blender_rw](images/environment_files_help/step_3a_create_api_blender_rw.jpg)
Noe the Identifier parameter should be exactly the the same as the domain / sub-domain of Blender since tokens will be issued with `aud` parameter for this domain.

This is shown below.

![create_api_spotlight_login](images/environment_files_help/step_3b_create_api_spotlight_login.jpg)

You should now have two APIs and four scopes. We will now create two applications:

- One for enabling token issuance for Flight Blender
- One to enable OIDC logging in

## Create a Application for Flight Blender

Go to the Passport Applications section and add a new application. Note that the Client ID and Client secret are automatically generated and you will need to copy it before saving since the secret is hashed on save.

![create_blender_client](images/environment_files_help/step_4a_blender_client.jpg)

You can see the grant type and other settings as shown above, make sure you use the Blender RW audience that will enable the `blender.read` and `blender.write` scopes.

You will need the Client ID and Client Secret and the Passport URL to populate [Line 7-11](https://github.com/openutm/deployment/blob/main/env.examples/.spotlight.env.example#L7-L11) in the environment file. The scope should read `blender.read blender.write` and the audience should be `testflight.flightblender.com` or something similar (according to your domain)

## Create Application for Flight Spotlight Login

Go to the Passport Applications section and add a new application. Note that the Client ID and Client secret are automatically generated and you will need to copy it before saving since the secret is hashed on save.

![create_spotlight_client](images/environment_files_help/step_4b_spotlight_client.jpg)

You will the Client ID and Client Secret and the Callback URL to fill [Line 22-25](https://github.com/openutm/deployment/blob/main/env.examples/.spotlight.env.example#L22-L25) in the spotlight environment file with the C.

## Populate the rest of the Blender Environment file and Deploy

Fill in the [proposed URL](https://github.com/openutm/deployment/blob/main/env.examples/.blender.env.example#L15) of Flight Spotlight and redis locations in the file file use the repository to deploy Flight Blender

## Populate the rest of the Spotlight Environment file

Fill in the values for [Redis and Tile 38](https://github.com/openutm/deployment/blob/main/env.examples/.spotlight.env.example#L28-L30) and redeploy.

You should be able to login to the system.
