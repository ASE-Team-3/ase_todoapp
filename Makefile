# Makefile for building and running the Docker container

# Variables
IMAGE_NAME=ase_todoapp
CONTAINER_NAME=ase_todoapp
DEVICE_IP=192.168.0.66
DEVICE_PORT=5555

# Build the Docker image
build:
	docker build . -t $(IMAGE_NAME)

# Run the Docker container
run:
	docker run --name $(CONTAINER_NAME) -v .:/app -dit $(IMAGE_NAME)

# Stop the Docker container
stop:
	docker stop $(CONTAINER_NAME)

# Delete the Docker container
delete-container:
	docker rm -f $(CONTAINER_NAME)

# Clean up all Docker images and containers (optional)
clean:
	docker system prune -a --volumes

# Flutter run inside the Docker container
flutter-run:
	docker exec -it $(CONTAINER_NAME) flutter run

# Execute flutter doctor with verbose output inside the Docker container
flutter-doctor:
	docker exec -it $(CONTAINER_NAME) flutter doctor --verbose

# Add a device using adb inside the Docker container
adb-connect:
	docker exec -it $(CONTAINER_NAME) adb connect $(DEVICE_IP):$(DEVICE_PORT)
	docker exec -it $(CONTAINER_NAME) adb devices

# Help message (optional)
help:
	@echo "Usage: make [target]"
	@echo "Available targets:"
	@echo "  build              Build the Docker image"
	@echo "  run                Run the Docker container"
	@echo "  stop               Stop the Docker container"
	@echo "  delete-container   Delete the Docker container"
	@echo "  clean              Clean up all Docker images and containers"
	@echo "  flutter-run        Run Flutter inside the Docker container"
	@echo "  flutter-doctor     Execute Flutter doctor with verbose output inside the Docker container"
	@echo "  adb-connect        Add a device using adb inside the Docker container"

# Default target
.PHONY: build run stop delete-container clean flutter-run flutter-doctor adb-connect help