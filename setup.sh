#!/bin/bash

# Product Funnel & Retention Analysis - Setup Script
# This script sets up the Python environment and validates BigQuery access

set -e  # Exit on any error

echo "========================================"
echo "Product Funnel & Retention Analysis"
echo "Environment Setup"
echo "========================================"
echo ""

# Check Python version
echo "1. Checking Python version..."
python_version=$(python3 --version 2>&1 | awk '{print $2}')
echo "   Found: Python $python_version"

if [[ "$(printf '%s\n' "3.9" "$python_version" | sort -V | head -n1)" != "3.9" ]]; then
    echo "   ⚠ Warning: Python 3.9+ recommended (found $python_version)"
else
    echo "   ✓ Python version OK"
fi
echo ""

# Create virtual environment
echo "2. Creating virtual environment..."
if [ -d "venv" ]; then
    echo "   Virtual environment already exists. Skipping."
else
    python3 -m venv venv
    echo "   ✓ Virtual environment created"
fi
echo ""

# Activate virtual environment
echo "3. Activating virtual environment..."
source venv/bin/activate
echo "   ✓ Activated"
echo ""

# Upgrade pip
echo "4. Upgrading pip..."
pip install --upgrade pip --quiet
echo "   ✓ pip upgraded"
echo ""

# Install dependencies
echo "5. Installing Python dependencies..."
pip install -r requirements.txt --quiet
echo "   ✓ Dependencies installed"
echo ""

# Check for gcloud CLI
echo "6. Checking for gcloud CLI..."
if command -v gcloud &> /dev/null; then
    echo "   ✓ gcloud CLI found"
    gcloud_version=$(gcloud version | head -n1)
    echo "   Version: $gcloud_version"
else
    echo "   ⚠ gcloud CLI not found"
    echo "   Install from: https://cloud.google.com/sdk/docs/install"
fi
echo ""

# Check authentication status
echo "7. Checking BigQuery authentication..."
if command -v gcloud &> /dev/null; then
    if gcloud auth application-default print-access-token &> /dev/null; then
        echo "   ✓ Application Default Credentials configured"
        project=$(gcloud config get-value project 2>/dev/null)
        echo "   Current project: $project"
    else
        echo "   ✗ Not authenticated"
        echo ""
        echo "   To authenticate, run ONE of:"
        echo "     1. gcloud auth application-default login"
        echo "     2. export GOOGLE_APPLICATION_CREDENTIALS=/path/to/service-account.json"
    fi
else
    echo "   ⚠ Cannot check auth status (gcloud not installed)"
fi
echo ""

# Test BigQuery access (optional)
echo "8. Testing BigQuery access..."
echo "   Running test query against GA4 public dataset..."
python3 << EOF
try:
    from google.cloud import bigquery
    client = bigquery.Client()
    query = "SELECT COUNT(*) as count FROM \`bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20210101\` LIMIT 1"
    result = client.query(query).to_dataframe()
    count = result['count'].iloc[0]
    print(f"   ✓ Successfully queried public dataset")
    print(f"   Sample event count: {count:,}")
except Exception as e:
    print(f"   ✗ BigQuery access test failed")
    print(f"   Error: {str(e)}")
    print("")
    print("   Make sure you have:")
    print("     1. Authenticated to BigQuery (see step 7)")
    print("     2. A valid Google Cloud project")
    print("     3. BigQuery API enabled")
EOF
echo ""

# Validate project structure
echo "9. Validating project structure..."
required_files=(
    "sql/base_events.sql"
    "sql/funnel.sql"
    "sql/retention_weekly.sql"
    "sql/retention_day_n.sql"
    "notebooks/analysis.ipynb"
    "README.md"
    "executive_summary.md"
    "requirements.txt"
)

all_exist=true
for file in "${required_files[@]}"; do
    if [ -f "$file" ]; then
        echo "   ✓ $file"
    else
        echo "   ✗ Missing: $file"
        all_exist=false
    fi
done

if [ -d "figures" ]; then
    echo "   ✓ figures/ directory"
else
    echo "   ⚠ figures/ directory not found (will be created when notebook runs)"
fi
echo ""

# Final status
echo "========================================"
echo "Setup Complete"
echo "========================================"
echo ""
echo "Next steps:"
echo "  1. Ensure BigQuery authentication (see step 7 above)"
echo "  2. Start Jupyter: jupyter notebook"
echo "  3. Open: notebooks/analysis.ipynb"
echo "  4. Run all cells to execute analysis"
echo ""
echo "For help, see README.md"
echo ""
