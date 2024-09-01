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

        # Start the Terraform process
        subprocess.run(['terraform', 'init'], cwd='./terraform')
        subprocess.run(['terraform', 'apply', '-auto-approve'], cwd='./terraform')

        # Retrieve the public IP from the Terraform output
        public_ip = subprocess.check_output(
            ['terraform', 'output', '-raw', 'instance_public_ip'],
            cwd='./terraform'
        ).decode('utf-8').strip()

        # Redirect to the timer page, passing the public IP
        return redirect(url_for('timer', public_ip=public_ip))

    return render_template('index.html')

@app.route('/timer')
def timer():
    public_ip = request.args.get('public_ip')
    return render_template('timer.html', public_ip=public_ip)

@app.route('/result')
def result():
    public_ip = request.args.get('public_ip')
    return render_template('result.html', public_ip=public_ip)

if __name__ == '__main__':
    app.run(host="0.0.0.0", port=80, debug=True)
