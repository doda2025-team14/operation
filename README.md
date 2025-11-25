# SMS Checker

This is an SMS Checker app that identifies whether an SMS message is considered a spam or not (ham).

# Run the application

### Requirements

To run this application, you need to have Docker and Docker Compose installed.

### Process

1. Clone the operation repository.

2. Create a  ```.env``` file and define the exposed port of the localhost. If you don't define any, 8080 will be used as a default port. Here is an example of the contents of the ```.env``` file: 

```HOST_PORT=9000```

3. To start the application, run the following command ```docker compose up -d```

If the command runs successfully, congratulations! The web app can be accessed by typing this link on the browser: ```http://localhost:{HOST_PORT}/sms/```. For example, if you use the default port, type: ```http://localhost:8080/sms/```.

