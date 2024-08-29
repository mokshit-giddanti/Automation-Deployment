from flask import Flask, request, render_template, redirect, url_for
import subprocess
import time

app = Flask(__name__)

@app.route('/', methods=['GET', 'POST'])
def index():
    if request.method == 'POST':
        access_key = request.form['access_key']
        secret_key = request.form['secret_key']
        github_repo_url = request.form['github_repo_url']

        # Save the variables to a file
        with open('terraform/terraform.tfvars', 'w') as f:
            f.write(f'access_key = "{access_key}"\n')
            f.write(f'secret_key = "{secret_key}"\n')
            f.write(f'github_repo_url = "{github_repo_url}"\n')

        # Run Terraform commands in the 'terraform' directory
        subprocess.run(['terraform', 'init'], cwd='./terraform', check=True)
        subprocess.run(['terraform', 'apply', '-auto-approve'], cwd='./terraform', check=True)

        # Get the output IP address
        result = subprocess.run(['terraform', 'output', 'instance_public_ip'], cwd='terraform', capture_output=True, text=True)
        public_ip = result.stdout.strip()
        return render_template('result.html', public_ip=public_ip)

    return render_template('index.html')

@app.route('/timer')
def timer():
    return render_template('timer.html')

if __name__ == '__main__':
    app.run(host="0.0.0.0", port=80, debug=True)
