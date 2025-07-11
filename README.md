# UAV Autonomy Module

## Objective

Provides autonomous flight capabilities for UAV systems. Handles flight control, mission planning, and vehicle command interfaces with PX4 support.

## Structure

```
uav_autonomy/
├── docker/
│   └── Dockerfile          # ROS2 Humble + PX4 messages + dependencies
├── utils/
│   └── entrypoint.sh       # Container startup script
├── ros_packages/           # ROS2 packages for autonomy
├── build.sh               # Build script
├── run.sh                 # Run script
├── clean.sh               # Cleanup script
└── docker-compose.yml     # Container orchestration
```

## Usage

### Local Development

```bash
# Build image locally
./build.sh tag=v1.0

# Run container
./run.sh tag=v1.0
```

### Multi-Architecture Build (for Jetson deployment)

```bash
# Build and push to Docker Hub (supports AMD64 + ARM64)
./build.sh tag=v1.0 multiarch=true registry=your-username/repo-name

# Use on Jetson or PC
./run.sh tag=v1.0 registry=your-username/repo-name
```

### ARM64 Only Build

```bash
# Build for ARM64 (Jetson)
./build.sh arm=true tag=v1.0-arm64

# Push to registry
./build.sh arm=true tag=v1.0-arm64 push=true registry=your-username/repo-name
```

### Cleanup

```bash
# Interactive cleanup
./clean.sh

# Remove specific tag
./clean.sh tag=v1.0

# Remove all images
./clean.sh all=true
```

## Dependencies

- Docker with buildx support
- ROS2 Humble base image
- PX4 messages (automatically included)
- NVIDIA runtime (for GPU support)

## Notes

- The `ros_packages/` directory is mounted as a volume for development
- Multi-arch builds automatically push to the registry (buildx limitation)
- Requires Docker Hub login for push operations
- Single architecture builds are stored locally by default

## Build Behavior

### Single Architecture (local)
```bash
./build.sh tag=v1.0                    # Builds locally, no push
./build.sh tag=v1.0 push=true          # Builds locally, then pushes
```

### Multi-Architecture (automatic push)
```bash
./build.sh tag=v1.0 multiarch=true     # Builds AND pushes automatically
```

Multi-arch builds cannot be stored locally due to Docker buildx limitations, so they are automatically pushed to the registry. 