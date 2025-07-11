#!/bin/bash

set -e

# Default values
ARM_BUILD=false
IMAGE_TAG="latest"
ARM_PLATFORM="linux/arm64"
PUSH_IMAGE=false
MULTI_ARCH=false
REGISTRY="uav_autonomy"  # Default local name

# Parse arguments
for arg in "$@"; do
    case $arg in
        arm=true)
            ARM_BUILD=true
            shift
            ;;
        tag=*)
            IMAGE_TAG="${arg#*=}"
            shift
            ;;
        push=true)
            PUSH_IMAGE=true
            shift
            ;;
        multiarch=true)
            MULTI_ARCH=true
            PUSH_IMAGE=true
            shift
            ;;
        registry=*)
            REGISTRY="${arg#*=}"
            shift
            ;;
        *)
            echo "Unknown argument: $arg"
            echo "Usage: ./build.sh [arm=true] [tag=your_tag] [push=true] [multiarch=true] [registry=namespace/image]"
            echo ""
            echo "Examples:"
            echo "  ./build.sh tag=v1.0                                    # Local build"
            echo "  ./build.sh arm=true tag=v1.0-arm64                     # ARM64 specific tag"
            echo "  ./build.sh tag=v1.0 registry=victormatteus04/pequi     # Custom registry"
            echo "  ./build.sh tag=v1.0 multiarch=true registry=victormatteus04/pequi  # Multi-arch push"
            exit 1
            ;;
    esac
done

if [ "$MULTI_ARCH" = true ]; then
    IMAGE_NAME="${REGISTRY}:${IMAGE_TAG}"
    echo "=== UAV Autonomy Multi-Arch Build ==="
    echo "Image: ${IMAGE_NAME}"
    echo "Platforms: linux/amd64,linux/arm64"
    
    # Check if buildx is available
    if ! docker buildx version >/dev/null 2>&1; then
        echo "Error: docker buildx not available. Install Docker Desktop or enable buildx."
        exit 1
    fi
    
    # Create or use existing builder
    if ! docker buildx inspect multiarch-builder >/dev/null 2>&1; then
        echo "Creating multi-arch builder..."
        docker buildx create --name multiarch-builder --driver docker-container --bootstrap
    fi
    
    echo "Building and pushing multi-arch image..."
    docker buildx build \
        --builder multiarch-builder \
        --platform linux/amd64,linux/arm64 \
        --file ./docker/Dockerfile \
        --tag ${IMAGE_NAME} \
        --push \
        .
        
    echo "✅ Multi-arch build and push completed!"
    echo "Image: ${IMAGE_NAME} (supports amd64 + arm64)"
    echo ""
    echo "🚀 Pull on any architecture:"
    echo "   docker pull ${IMAGE_NAME}"
    echo ""
    echo "🔍 Verify multi-arch:"
    echo "   docker manifest inspect ${IMAGE_NAME}"
    exit 0
fi

# Single architecture build
IMAGE_NAME="${REGISTRY}:${IMAGE_TAG}"

if [ "$ARM_BUILD" = true ]; then
    PLATFORM_FLAG="--platform ${ARM_PLATFORM}"
    PLATFORM_DESC="${ARM_PLATFORM} (ARM64 for Jetson)"
else
    PLATFORM_FLAG=""
    PLATFORM_DESC="native"
fi

echo "=== UAV Autonomy Build ==="
echo "Image: ${IMAGE_NAME}"
echo "Platform: ${PLATFORM_DESC}"

# Check if Docker is running
if ! docker info >/dev/null 2>&1; then
    echo "Error: Docker is not running. Please start Docker first."
    exit 1
fi

# Build the Docker image
echo "Building Docker image..."
if [ "$ARM_BUILD" = true ]; then
    # Use buildx for ARM64
    docker buildx build \
        --platform ${ARM_PLATFORM} \
        --file ./docker/Dockerfile \
        --tag ${IMAGE_NAME} \
        --load \
        .
else
    # Regular build
    docker build \
        --file ./docker/Dockerfile \
        --tag ${IMAGE_NAME} \
        .
fi

# Check if build was successful
if [ $? -eq 0 ]; then
    echo "✅ Build completed successfully!"
    echo "Image: ${IMAGE_NAME}"
else
    echo "❌ Build failed!"
    exit 1
fi

# Push if requested
if [ "$PUSH_IMAGE" = true ]; then
    echo "Pushing image to registry..."
    docker push ${IMAGE_NAME}
    echo "✅ Push completed!"
fi

# Build ROS packages
echo "Building ROS packages..."
docker run --rm \
    -v $(pwd)/ros_packages:/ros2_ws/src:rw \
    ${IMAGE_NAME} \
    bash -c "source /opt/ros/humble/setup.bash && source /px4_ws/install/setup.bash && cd /ros2_ws && colcon build --symlink-install"

echo "=== Build completed! ==="
echo "To run: ./run.sh tag=${IMAGE_TAG} registry=${REGISTRY}"
echo "Image: ${IMAGE_NAME}" 