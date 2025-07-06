#!/bin/bash

# Supabase Setup Script for mic-for-mac
# This script helps you configure your Supabase environment variables

set -e

echo "🐕 mic-for-mac Supabase Setup"
echo "=============================="
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if .env file exists
if [ -f ".env" ]; then
    print_warning ".env file already exists. Do you want to overwrite it? (y/N)"
    read -r response
    if [[ ! "$response" =~ ^[Yy]$ ]]; then
        print_status "Setup cancelled."
        exit 0
    fi
fi

print_status "Let's set up your Supabase configuration!"
echo ""

# Get Supabase URL
print_status "Enter your Supabase project URL (e.g., https://your-project-ref.supabase.co):"
read -r supabase_url

if [ -z "$supabase_url" ]; then
    print_error "Supabase URL is required!"
    exit 1
fi

# Validate URL format
if [[ ! "$supabase_url" =~ ^https://.*\.supabase\.co$ ]]; then
    print_warning "URL format doesn't look like a standard Supabase URL. Continuing anyway..."
fi

# Get Supabase anon key
print_status "Enter your Supabase anonymous key:"
read -r supabase_anon_key

if [ -z "$supabase_anon_key" ]; then
    print_error "Supabase anonymous key is required!"
    exit 1
fi

# Get OpenAI API key (optional)
print_status "Enter your OpenAI API key (optional, for transcription):"
read -r openai_api_key

# Create .env file
print_status "Creating .env file..."
cat > .env << EOF
SUPABASE_URL=$supabase_url
SUPABASE_ANON_KEY=$supabase_anon_key
EOF

if [ -n "$openai_api_key" ]; then
    echo "OPENAI_API_KEY=$openai_api_key" >> .env
fi

print_success ".env file created successfully!"

# Create .env.example file
print_status "Creating .env.example file..."
cat > .env.example << 'EOF'
SUPABASE_URL=https://your-project-ref.supabase.co
SUPABASE_ANON_KEY=your-anon-key
OPENAI_API_KEY=your-openai-api-key
EOF

print_success ".env.example file created!"

# Instructions for Xcode
echo ""
print_status "Next steps:"
echo "1. Open your project in Xcode"
echo "2. Edit your scheme: Product → Scheme → Edit Scheme"
echo "3. Go to Run → Arguments → Environment Variables"
echo "4. Add the variables from your .env file:"
echo "   - SUPABASE_URL"
echo "   - SUPABASE_ANON_KEY"
echo "   - OPENAI_API_KEY (if provided)"
echo ""
print_status "Or set them in your shell:"
echo "export SUPABASE_URL=\"$supabase_url\""
echo "export SUPABASE_ANON_KEY=\"$supabase_anon_key\""
if [ -n "$openai_api_key" ]; then
    echo "export OPENAI_API_KEY=\"$openai_api_key\""
fi
echo ""

# Check if we can validate the configuration
print_status "Would you like to validate your Supabase configuration? (y/N)"
read -r validate_response
if [[ "$validate_response" =~ ^[Yy]$ ]]; then
    print_status "Validating configuration..."
    
    # Simple validation using curl
    if command -v curl &> /dev/null; then
        response=$(curl -s -o /dev/null -w "%{http_code}" "$supabase_url/rest/v1/" -H "apikey: $supabase_anon_key" -H "Authorization: Bearer $supabase_anon_key" || echo "000")
        
        if [ "$response" = "200" ] || [ "$response" = "401" ]; then
            print_success "Supabase connection successful! (HTTP $response)"
        else
            print_warning "Could not connect to Supabase. Please check your URL and key."
        fi
    else
        print_warning "curl not found. Skipping connection validation."
    fi
fi

echo ""
print_success "Setup complete! 🎉"
print_status "Don't forget to:"
echo "1. Run the SQL scripts from SUPABASE_SETUP.md in your Supabase dashboard"
echo "2. Create the required storage buckets"
echo "3. Set up Row Level Security policies"
echo ""
print_status "For detailed instructions, see SUPABASE_SETUP.md" 