#!/bin/bash

set -e

# Default values
CLEAN_ALL=false
SPECIFIC_TAG=""
FORCE=false

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Parse arguments
for arg in "$@"; do
    case $arg in
        all=true)
            CLEAN_ALL=true
            shift
            ;;
        tag=*)
            SPECIFIC_TAG="${arg#*=}"
            shift
            ;;
        force=true)
            FORCE=true
            shift
            ;;
        *)
            echo "Unknown argument: $arg"
            echo "Usage: ./clean.sh [all=true] [tag=specific_tag] [force=true]"
            echo ""
            echo "Examples:"
            echo "  ./clean.sh                    # Interactive cleanup"
            echo "  ./clean.sh tag=v1.0          # Remove specific tag"
            echo "  ./clean.sh all=true          # Remove all uav_autonomy images"
            echo "  ./clean.sh all=true force=true  # Remove all without confirmation"
            exit 1
            ;;
    esac
done

echo -e "${BLUE}=== UAV Autonomy Cleanup ===${NC}"

# Function to remove specific tag
remove_tag() {
    local tag=$1
    echo -e "${YELLOW}Searching for images with tag: ${tag}${NC}"
    
    # Find images with the specific tag
    IMAGES=$(docker images --format "table {{.Repository}}:{{.Tag}}" | grep ":${tag}$" || true)
    
    if [ -z "$IMAGES" ]; then
        echo -e "${YELLOW}No images found with tag: ${tag}${NC}"
        return
    fi
    
    echo -e "${RED}Images to be removed:${NC}"
    echo "$IMAGES"
    
    if [ "$FORCE" != true ]; then
        echo -e "${YELLOW}Do you want to remove these images? (y/N)${NC}"
        read -r response
        if [[ ! "$response" =~ ^[Yy]$ ]]; then
            echo -e "${BLUE}Cleanup cancelled.${NC}"
            return
        fi
    fi
    
    echo "$IMAGES" | while read -r image; do
        if [ ! -z "$image" ]; then
            echo -e "${RED}Removing: ${image}${NC}"
            docker rmi "$image" 2>/dev/null || echo -e "${YELLOW}Warning: Could not remove ${image}${NC}"
        fi
    done
}

# Function to remove all UAV autonomy images
remove_all() {
    echo -e "${YELLOW}Searching for all UAV autonomy related images...${NC}"
    
    # Find all images related to uav_autonomy
    IMAGES=$(docker images --format "table {{.Repository}}:{{.Tag}}" | grep -E "(uav_autonomy|victormatteus04/pequi)" || true)
    
    if [ -z "$IMAGES" ]; then
        echo -e "${YELLOW}No UAV autonomy images found.${NC}"
        return
    fi
    
    echo -e "${RED}All UAV autonomy images to be removed:${NC}"
    echo "$IMAGES"
    
    if [ "$FORCE" != true ]; then
        echo -e "${YELLOW}Do you want to remove ALL these images? (y/N)${NC}"
        read -r response
        if [[ ! "$response" =~ ^[Yy]$ ]]; then
            echo -e "${BLUE}Cleanup cancelled.${NC}"
            return
        fi
    fi
    
    echo "$IMAGES" | while read -r image; do
        if [ ! -z "$image" ]; then
            echo -e "${RED}Removing: ${image}${NC}"
            docker rmi "$image" 2>/dev/null || echo -e "${YELLOW}Warning: Could not remove ${image}${NC}"
        fi
    done
}

# Function for interactive cleanup
interactive_cleanup() {
    echo -e "${YELLOW}Available UAV autonomy images:${NC}"
    docker images --format "table {{.Repository}}\t{{.Tag}}\t{{.Size}}\t{{.CreatedAt}}" | head -1
    docker images --format "table {{.Repository}}\t{{.Tag}}\t{{.Size}}\t{{.CreatedAt}}" | grep -E "(uav_autonomy|victormatteus04/pequi)" || echo -e "${YELLOW}No UAV autonomy images found.${NC}"
    
    echo ""
    echo -e "${BLUE}Cleanup options:${NC}"
    echo "1) Remove specific tag"
    echo "2) Remove all UAV autonomy images"
    echo "3) Cancel"
    
    echo -e "${YELLOW}Choose an option (1-3):${NC}"
    read -r choice
    
    case $choice in
        1)
            echo -e "${YELLOW}Enter the tag to remove:${NC}"
            read -r tag
            remove_tag "$tag"
            ;;
        2)
            remove_all
            ;;
        3)
            echo -e "${BLUE}Cleanup cancelled.${NC}"
            ;;
        *)
            echo -e "${RED}Invalid option.${NC}"
            ;;
    esac
}

# Main logic
if [ "$CLEAN_ALL" = true ]; then
    remove_all
elif [ ! -z "$SPECIFIC_TAG" ]; then
    remove_tag "$SPECIFIC_TAG"
else
    interactive_cleanup
fi

# Clean up dangling images
echo -e "${BLUE}Cleaning up dangling images...${NC}"
DANGLING=$(docker images -f "dangling=true" -q)
if [ ! -z "$DANGLING" ]; then
    docker rmi $DANGLING 2>/dev/null || echo -e "${YELLOW}Warning: Could not remove some dangling images${NC}"
    echo -e "${GREEN}Dangling images cleaned.${NC}"
else
    echo -e "${YELLOW}No dangling images found.${NC}"
fi

echo -e "${GREEN}=== Cleanup completed! ===${NC}" 