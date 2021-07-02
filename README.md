# Collector, Analyst, and Presenter Example System

This repository contains an example system consitig of three web services that highlights the usage of [Collector](https://github.com/Apodini/Collector), [Analyst](https://github.com/Apodini/Analyst), and [Presenter](https://github.com/Apodini/Presenter) in combination with the [Apodini](https://github.com/Apodini/Apodini) framework using [ApodiniCollector](https://github.com/Apodini/ApodiniCollector) and [ApodiniAnalystPresenter](https://github.com/Apodini/ApodiniAnalystPresenter).
It features a database web service, a processing web service, and a gateway that offers the public API of the web service. All web services collect metrics and traces using the [Collector](https://github.com/Apodini/Collector) framework.
A client application allows developers to observe inisights generated using [Analyst](https://github.com/Apodini/Analyst) and pesented using [Presenter](https://github.com/Apodini/Presenter):
<p float="left">
 <img width="350" alt="Screenshot of the client application showing the connect screen. The connect screen shows a text field to enter the hostname of the system and a button to start connecting to the Presenter endpoint" src="https://user-images.githubusercontent.com/28656495/124276854-a35d6c80-db44-11eb-9abf-80a26e8e96d1.png">
 <img width="350" alt="Screenshot of the main screen that allows developers to observe the system. It shows three sections that a developer can tap on to display more information about the three deployed web services." src="https://user-images.githubusercontent.com/28656495/124276863-a6585d00-db44-11eb-8f2b-81602855eb8d.png">
</p>

## <a name="RunTheExampleSystem"></a>Run the Example System

You can start the web services on any system that supports [docker](https://www.docker.com) and [docker compose](https://docs.docker.com/compose/). Follow the instructions on https://docs.docker.com/compose/install/ to install docker and docker compose.
You will need a macOS instance to build and run the example application. Xcode 13 is required to build and run the example client application. Follow the instructions on https://developer.apple.com/xcode/ to install the latest version of Xcode.

1. Start the web services by running the `$ docker compose up` command in the root of the repository. It compiles and starts up all three web services as well as adjacently deployed [Jaeger](https://www.jaegertracing.io) and [Prometheus](https://prometheus.io) instances.
2. You can now interact with the API using your favorite tool to explore RESTful APIs. The section [System Functionality](#SystemFunctionality) includes a detailed description of the API endpoints.
3. Start the client application by opening the *Example.xcodeproj* in the *Client* folder. Once the project you can start the application by following the instructions on [Running Your App in the Simulator or on a Device](https://developer.apple.com/documentation/xcode/running-your-app-in-the-simulator-or-on-a-device)
  
## <a name="SystemFunctionality"></a>System Functionality

The system can collect locations shared by users and generates hotspots indicating frequently visited places. Please note that this is a demo system and does not include any authentication or authorization mechanisms.

**Create a new location entry:**

`POST` at `/v1/user/{userID}/location`, e.g. [`http://localhost/v1/user/1/location`](http://localhost/v1/user/1/location) with a payload encoded in JSON (header `Content-Type` set to `application/json`) that encodes a location: {"latitude": 0.0, "longitude": 0.0}`.  
You can try out the following curl command to set a request to the gateway:
```bash
curl --header "Content-Type: application/json" \
   --request POST \
   --data '{"latitude": 42.0, "longitude": 24.0}' \
   http://localhost/v1/user/1/locations
```

**Get hotspots**

`GET` at `/v1/user/{userID}/hotspots`, e.g. [`http://localhost/v1/user/1/hotspots`](http://localhost/v1/user/1/hotspots) that returns the calculated hotspots.  
You can try out the following curl command to get a list of hotspots:
```bash
curl http://localhost/v1/user/1/hotspots
```

**Metrics and Presenter Handler**

In addition, the gateway includes a `/v1/metrics` endpoint to deliver metrics information to Prometheus and a `/v1/metrics-ui` endpoint that delivers the [Presenter](https://github.com/Apodini/Presenter) UI to the client application.

## <a name="DevelopmentSetup"></a>Development Setup

To easily continue developing the example system, you can open the *Example.xcworkspace* found at the root of the repo using Xcode. The workspace bundles all three web services and the client application. You can run and build the client application and web services as described in [Running Your App in the Simulator or on a Device](https://developer.apple.com/documentation/xcode/running-your-app-in-the-simulator-or-on-a-device) by selecting the corresponding scheme.

To test the collection of metrics and traces, you can run the `$ docker compose -f docker-compose-development.yml up` command in the root of the repo start-up adjacently deployed [Jaeger](https://www.jaegertracing.io) and [Prometheus](https://prometheus.io) instances used by the web services. All web services are configured to connect to the instances started using the `$ docker compose -f docker-compose-development.yml up` command.

## Contributing
Contributions to this project are welcome. Please make sure to read the [contribution guidelines](https://github.com/Apodini/.github/blob/release/CONTRIBUTING.md) first.

## License
This project is licensed under the MIT License. See [License](https://github.com/Apodini/CollectorAnalystPresenterExample/blob/release/LICENSE) for more information.
