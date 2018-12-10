from flask import Flask, jsonify, request
from flask_cors import CORS


# configuration
DEBUG = True

# instantiate the app
app = Flask(__name__)
app.config.from_object(__name__)

# enable CORS
CORS(app)



# sanity check route
@app.route('/main', methods=['GET', 'POST'])
def all_adresses():
	response_object = {'status': 'response'}
	if request.method == 'POST':
		post_data = request.get_json()
		if post_data.get('address') not in ADDRESSES:
			ADDRESSES.append(post_data.get('address'))
	else:
		response_object['message'] = ADDRESSES
	return jsonify(response_object)

if __name__ == '__main__':
    app.run()
