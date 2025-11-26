from flask import Flask, render_template, request, jsonify
import os
import logging
from datetime import datetime
import psutil

app = Flask(__name__)

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

@app.route('/')
def home():
    """Home page"""
    return render_template('index.html')

@app.route('/health')
def health():
    """Health check endpoint"""
    return jsonify({
        'status': 'healthy',
        'timestamp': datetime.utcnow().isoformat(),
        'version': os.getenv('APP_VERSION', '1.0.0')
    })

@app.route('/api/info')
def info():
    """System information endpoint"""
    try:
        cpu_percent = psutil.cpu_percent(interval=1)
        memory = psutil.virtual_memory()
        
        return jsonify({
            'hostname': os.getenv('HOSTNAME', 'unknown'),
            'cpu_usage': f"{cpu_percent}%",
            'memory_usage': f"{memory.percent}%",
            'environment': os.getenv('ENVIRONMENT', 'development')
        })
    except Exception as e:
        logger.error(f"Error getting system info: {str(e)}")
        return jsonify({'error': 'Unable to fetch system info'}), 500

@app.route('/api/data', methods=['GET', 'POST'])
def data():
    """API endpoint for data operations"""
    if request.method == 'POST':
        data = request.get_json()
        logger.info(f"Received data: {data}")
        return jsonify({
            'message': 'Data received successfully',
            'received': data
        }), 201
    else:
        return jsonify({
            'message': 'Use POST to submit data',
            'example': {'key': 'value'}
        })

@app.route('/api/files')
def list_files():
    """List files endpoint - intentionally vulnerable for testing"""
    # This endpoint will trigger Falco alerts when accessed suspiciously
    try:
        directory = request.args.get('dir', '/app')
        # Restricted to /app directory only for safety
        if not directory.startswith('/app'):
            return jsonify({'error': 'Access denied'}), 403
        
        files = os.listdir(directory)
        return jsonify({'directory': directory, 'files': files})
    except Exception as e:
        logger.error(f"Error listing files: {str(e)}")
        return jsonify({'error': str(e)}), 500

@app.errorhandler(404)
def not_found(error):
    """404 error handler"""
    return jsonify({'error': 'Not found'}), 404

@app.errorhandler(500)
def internal_error(error):
    """500 error handler"""
    logger.error(f"Internal error: {str(error)}")
    return jsonify({'error': 'Internal server error'}), 500

if __name__ == '__main__':
    port = int(os.getenv('PORT', 5000))
    app.run(host='0.0.0.0', port=port, debug=False)