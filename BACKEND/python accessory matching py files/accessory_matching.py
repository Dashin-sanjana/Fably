from flask import Flask, request, jsonify # type: ignore
import os
import cv2 as c
from dotenv import load_dotenv # type: ignore
import tensorflow as tf # type: ignore

#import tensorflow_hub as hub # type: ignore

from werkzeug.utils import secure_filename # type: ignore

# logging for potential issues.
import logging

# importing form machine learning model.
from ml_model import (
    find_closest_colors,
    match_given_colors,
    matching_colors_between_outfits_and_accessories, 
    extract_main_colors, 
    predict_accessory, 
    predict_outfit, 
    load_feature_extraction_model,
    extract_features_efficientNetB0,
    compare_feature_vectors
)


# loading environment variables from .env file.
load_dotenv()


# uploading files from following accessories folder paths.
UPLOAD_ACCESSORY_FOLDER = "static/images/accessories/"
BELT_FOLDER = os.path.join(UPLOAD_ACCESSORY_FOLDER, "belts"), CHAINS_FOLDER = os.path.join(UPLOAD_ACCESSORY_FOLDER, "chains"), GLASSES_FOLDER = os.path.join(UPLOAD_ACCESSORY_FOLDER, "glasses"), GLOVES_FOLDER = os.path.join(UPLOAD_ACCESSORY_FOLDER, "gloves"), HANDBAG_FOLDER = os.path.join(UPLOAD_ACCESSORY_FOLDER, "handbags"), HAT_FOLDER = os.path.join(UPLOAD_ACCESSORY_FOLDER, "hats"), RING_FOLDER = os.path.join(UPLOAD_ACCESSORY_FOLDER, "rings"), SHOE_FOLDER = os.path.join(UPLOAD_ACCESSORY_FOLDER, "shoes"), SOCK_FOLDER = os.path.join(UPLOAD_ACCESSORY_FOLDER, "socks"), WATCH_FOLDER = os.path.join(UPLOAD_ACCESSORY_FOLDER, "watches")

# uploading files from following outfit folder paths.
UPLOAD_OUTFIT_FOLDER = "static/images/outfits"
ACTIVEWEAR_FOLDER = os.path.join(UPLOAD_OUTFIT_FOLDER, "activewear"), BOHEMIAN_FOLDER = os.path.join(UPLOAD_OUTFIT_FOLDER, "bohemian"), CASUAL_FOLDER = os.path.join(UPLOAD_OUTFIT_FOLDER, "casual"), EVENINGWEAR_FOLDER = os.path.join(UPLOAD_OUTFIT_FOLDER, "eveningwear"), FORMAL_FOLDER = os.path.join(UPLOAD_OUTFIT_FOLDER, "formal"), INDIE_FOLDER = os.path.join(UPLOAD_OUTFIT_FOLDER, "indie"), KNITWEAR_FOLDER = os.path.join(UPLOAD_OUTFIT_FOLDER, "knitwear"), LOUNGEWEAR_FOLDER = os.path.join(UPLOAD_OUTFIT_FOLDER, "loungewear"), RETRO_FOLDER = os.path.join(UPLOAD_OUTFIT_FOLDER, "retro"), ROMANTIC_FOLDER = os.path.join(UPLOAD_OUTFIT_FOLDER, "romantic"), SMARTCASUAL_FOLDER = os.path.join(UPLOAD_OUTFIT_FOLDER, "smartcasual"), SPORTY_FOLDER = os.path.join(UPLOAD_OUTFIT_FOLDER, "sporty"), VINTAGE_FOLDER = os.path.join(UPLOAD_OUTFIT_FOLDER, "vintage")

# allowed file extensions. 
ALLOWED_EXTENSIONS = {'png', 'jpg', 'jpeg'}
# maximum length of 16MB.
MAX_CONTENT_LENGTH = 16 * 1024 * 1024


# creating feature app for accessory matching.
feature = Flask(__name__)
# uploading both accessory and outfit folders.
feature.config["UPLOAD_OUTFIT_FOLDER"] = UPLOAD_OUTFIT_FOLDER
feature.config["UPLOAD_ACCESSORY_FOLDER"] = UPLOAD_ACCESSORY_FOLDER
# file size limit for extra security for the program.
feature.config["MAX_CONTENT_LENGTH"] = MAX_CONTENT_LENGTH


# to ensure the accessory folders exist.
for accessory_folder in [BELT_FOLDER, CHAINS_FOLDER, GLASSES_FOLDER, GLOVES_FOLDER, HANDBAG_FOLDER, HAT_FOLDER, RING_FOLDER, SHOE_FOLDER, SOCK_FOLDER, WATCH_FOLDER]: os.makedirs(accessory_folder, exist_ok=True)

# to ensure the outfit folders exist.
for outfit_folder in [ACTIVEWEAR_FOLDER, BOHEMIAN_FOLDER, CASUAL_FOLDER, EVENINGWEAR_FOLDER, FORMAL_FOLDER, INDIE_FOLDER, KNITWEAR_FOLDER, LOUNGEWEAR_FOLDER, RETRO_FOLDER, ROMANTIC_FOLDER, SMARTCASUAL_FOLDER, SPORTY_FOLDER, VINTAGE_FOLDER]: os.makedirs(outfit_folder, exist_ok=True)

# creating a logger for information.
logging.basicConfig(level=logging.INFO)


# to ensure proper configuration for MAX_CONTENT_LENGTH.
@feature.errorhandler(413)
def request_too_large(error):
    return jsonify({"error": "File is Too Large! Max Content Length Exceeds 16MB."}), 413


# function for checking allowed file extensions.
def allowed_file(filename):
    return '.' in filename and filename.rsplit('.', 1)[1].lower() in ALLOWED_EXTENSIONS


# route for home page.
@feature.route('/')
def home():
    return jsonify({"message": "Accessory Matching API is Running."})


# matching accessories with outfits via posting the data.
@feature.route('/match', methods=["POST"])
def match_accessories_with_outfits():
    
    # sending results to frontend.
    results = {"feature similarity": {},
               "image color match": {},
               "image color delta e": {},
               "provided color match": {},
            }
    
    # initializing the list of file_paths, outfit_file_type, outfit_path and accessory_paths.
    file_paths = {}
    outfit_path = None
    accessory_paths = {}
    provided_accessory_colors = request.form.getList('accessory_colors[]')
    

    try:
        # a dictionary of requested accessory and outfit folders.
        all_accessory_and_outfit_files = {
            'belts': request.files.get('belts'),'chains': request.files.get('chains'),'glasses': request.files.get('glasses'),'gloves': request.files.get('gloves'),'handbags': request.files.get('handbags'),'hats': request.files.get('hats'),'rings': request.files.get('rings'),'shoes': request.files.get('shoes'),'socks': request.files.get('socks'),'watches': request.files.get('watches'),
            
            'activewear': request.files.get('activewear'),'bohemian': request.files.get('bohemian'),'casual': request.files.get('casual'),'eveningwear': request.files.get('eveningwear'),'formal': request.files.get('formal'),'indie': request.files.get('indie'),'knitwear': request.files.get('knitwear'),'loungewear': request.files.get('loungewear'),'retro': request.files.get('retro'),'romantic': request.files.get('romantic'),'smartcasual': request.files.get('smartcasual'),'sporty': request.files.get('sporty'),'vintage': request.files.get('vintage')
        }
        
        # if file names are null, and if files are not allowed.
        for file_type in all_accessory_and_outfit_files:
            if file_type not in all_accessory_and_outfit_files:
                return jsonify({"error": f"No File Part for {file_type}."}), 400
        
        required_files = {}
        # if file names are null, and if files are not allowed.
        for file_type, file in all_accessory_and_outfit_files.items():
            if file:
                if file.filename == "":
                    return jsonify({"error": f"No Selected File for {file_type}."}), 400
                if not allowed_file(file.filename):
                    return jsonify({"error": f"Invalid File Format for {file_type}."}), 400
                if len(file.read()) > MAX_CONTENT_LENGTH:
                    return jsonify({"error": f"Invalid File Format for {file_type}."}), 400
                file.seek(0)
                required_files[file_type] = file

        try:
            # saving and securing filenames.
            file_paths = {}
            for file_type, file in required_files.items():
                filename = secure_filename(file.filename)
                # saving data in each accessory file.
                if file_type in ['activewear', 'bohemian','casual', 'eveningwear','formal', 'indie','knitwear', 'loungewear','retro', 'romantic','smartcasual', 'sporty','vintage']:
                    
                    given_outfit_folder = os.path.join(UPLOAD_OUTFIT_FOLDER, file_type)
                    
                    filepath = os.path.join(given_outfit_folder, filename)
                    file.save(filepath)
                    file_paths[file_type] = filepath
                
                # saving data in each outfit file.
                else:
                    given_accessory_folder = os.path.join(UPLOAD_ACCESSORY_FOLDER, file_type)
                    
                    filepath = os.path.join(given_accessory_folder, filename)
                    file.save(filepath)
                    file_paths[file_type] = filepath
                
            # using the feature extraction model.
            feature_extraction_model = load_feature_extraction_model()
            outfit_features = None
            outfit_colors = None
            
            # extracting the main colors and features of each image file selected.
            if outfit_path:
                try:
                    outfit_img = c.imread(outfit_path)
                    if outfit_img is not None:
                        outfit_features = extract_features_efficientNetB0(outfit_path)
                        outfit_colors = extract_main_colors(outfit_path)
                        
                    else:
                        results["error"] = "Could Not Read Outfit Image."
                        
                except Exception as e:
                    results["error"] = {f"Unknown Error in Proccessing ${outfit_img} image: "+str(e)}

            # feature and color matching between outfits and accessories.
            if outfit_features is not None and outfit_colors is not None:
                for accessory_type, accessory_path in accessory_paths.items():
                    try:
                        accessory_img = c.imread(accessory_path)
                        if accessory_img is not None:
                            accessory_features = extract_features_efficientNetB0(accessory_path, feature_extraction_model)
                            accessory_colors = extract_main_colors(accessory_path)
                            
                            # returning the match result and similarity.
                            if accessory_features is not None:
                                match, similarity = compare_feature_vectors(outfit_features, accessory_features)
                                results['feature similarity'][accessory_type] = {"match": bool(match), "similarity": float(similarity)}
                            else:
                                results['feature similarity'][accessory_type] = {"match": False, "similarity": 0.0, "error": "Could Not Extract Features."}
                            
                            # returning the results for color matching between outfits and accessories.
                            if accessory_colors is not None:
                                color_match, calculate_delta_e = find_closest_colors(accessory_colors, outfit_colors)
                                results['image color match'][accessory_type] = color_match
                                results['image color delta e'][accessory_type] = calculate_delta_e
                            
                            else:
                                results['image color match'][accessory_type] = False
                                results['image color delta e'][accessory_type] = {"error": "Could Not Extract Features."}
                                
                        else:
                            results['feature similarity'][accessory_type] = {"match": False, "similarity": 0.0, "error": "Could Not Read Accessory Images."}
                            results['image color match'][accessory_type] = False
                            results['image color delta e'][accessory_type] = {"error": "Could Not Read Accessory Images."}
                            
                    except ValueError as e:
                        results["error"][accessory_type] = {f"Value Error in Proccessing ${accessory_type} image: "+str(e)}
                    except Exception as e:
                        results["error"][accessory_type] = {f"Unknown Error in Proccessing ${accessory_type} image: "+str(e)}
                    
            elif (outfit_path and not results.get('error')):
                results['warning'][accessory_type] = {"Could Not Extract Feautre from Outfit Image."}
                
            # getting all the selected colors from the frontend and for accessory macthing.
            if outfit_colors and provided_accessory_colors:
                for accessory_color in provided_accessory_colors:
                    try:
                        accessory_color_rgb = None
                        if accessory_color.startsWith("#"): accessory_color_rgb = tuple(int(accessory_color[i:i+2], 16) for i in (1, 3, 5))
                            
                        elif ',' in accessory_color: accessory_color_rgb = tuple(int(accessory_color.split(',')))

                        elif accessory_color in _colorsList:
                            color_map = {
                                'Amber': (255, 191, 0), 'Black': (0, 0, 0), 'Blue': (0, 0, 255), 'Emerald': (80, 200, 120), 'Gold': (255, 215, 0), 'Green': (0, 255, 0), 'Grey': (128, 128, 128), 'Indigo': (75, 0, 130), 'Jade': (0, 168, 107), 'Lemon': (255, 247, 0), 'Lilac': (200, 162, 200), 'Lime': (191, 255, 0), 'Midnight Blue': (25, 25, 112), 'Mint Green': (152, 255, 152), 'Navy Blue': (0, 0, 128), 'Olive': (128, 128, 0), 'Orange': (255, 140, 0), 'Peach': (255, 229, 180), 'Pink': (255, 192, 203), 'Platinum': (229, 224, 200), 'Plum': (221, 160, 221), 'Purple': (128, 0, 128), 'Red': (255, 0, 0), 'Rose': (255, 0, 127), 'Ruby': (224, 17, 95), 'Sapphire': (15, 82, 186), 'Scarlet': (255, 36, 0), 'Silver': (192, 192, 192), 'Turquoise': (64, 224, 208), 'Ultramarine': (18, 10, 143), 'Violet': (143, 0, 255), 'White': (255, 255, 255), 'Yellow': (255, 255, 0), 'Zucchini': (81, 97, 56)
                            }
                            
                            accessory_color_rgb = color_map.get(accessory_color)
                            
                        if accessory_color_rgb:
                            match, delta_e = match_given_colors([list(accessory_color_rgb)], outfit_colors)
                            results['provided color match'][accessory_color] = {"match": bool(match), "delta e": float(delta_e)}
                        else:
                            results[""][accessory_color]
                                    
                    except ValueError as e:
                        print(f"Error in Image Processing: {e}")
                        logging.error(f"Error: {e}")
                        return jsonify({"error": "ValueError in Image Processing."}), 500
                    except Exception as e:
                        print(f"Error in Image Processing: {e}")
                        logging.error(f"Error: {e}")
                        return jsonify({"error": "Unknown Error in Image Processing."}), 500




            
            
            # finding matches for each accessory and for each outfit.
            predictions = {}
            for file_type, img in images.items():
                if file_type in ['activewear', 'bohemian','casual', 'eveningwear','formal', 'indie','knitwear', 'loungewear','retro', 'romantic','smartcasual', 'sporty','vintage']:
                    
                    predictions[file_type] = predict_outfit(img, feature_extraction_model)
                
                else:
                    predictions[file_type] = predict_accessory(img, feature_extraction_model)
            
            # finding matches of colors between outfits and accessories.
            color_matches = {}
            outfit_file_type = next((ft for ft in images if ft in ['activewear', 'bohemian','casual', 'eveningwear','formal', 'indie','knitwear', 'loungewear','retro', 'romantic','smartcasual', 'sporty','vintage']), None)
            if outfit_file_type:
                outfit_colors = extract_main_colors(images[outfit_file_type])
                for file_type, img in images.items():
                    if file_type != 'outfit':
                        accessory_colors = extract_main_colors(img)
                        color_matches[file_type] = matching_colors_between_outfits_and_accessories(accessory_colors, outfit_colors)
            
            for file_type, prediction in predictions.items():
                if file_type not in ['activewear', 'bohemian','casual', 'eveningwear','formal', 'indie','knitwear', 'loungewear','retro', 'romantic','smartcasual', 'sporty','vintage']:
                    
                    results["pretrained accessory prediction"][file_type] = prediction[1]
                    results["pretrained accessory confidence"][file_type] = float(prediction[0])
                    results["pretrained accessory match found"][file_type] = prediction[1] == 1
            
            for file_type, color_match in color_matches.items():
                if color_match == False:
                    results["color match found message"] = "No Color Match Found!"
            
            any_acc_match = False
            for file_type, acc_match in color_matches.items():
                if acc_match:
                    any_acc_match = True
                    break
                
            if results["pretrained outfit match found"] == 1:
                any_acc_match = True

            if any_acc_match:
                results["pretrained match found message"] = "Pretrained Match Found!"
            
            return jsonify(results)

        except ValueError as e:
            print(f"ValueError: {e}")
            logging.error(f"ValueError: {e}")
            return jsonify({"error": str(e)}), 500
        except Exception as e:
            print(f"Error in Image Processing: {e}")
            logging.error(f"Error: {e}")
            return jsonify({"error": "Error in Image Processing."}), 500

    except ValueError as e:
        print(f"ValueError: {e}")
        logging.error(f"ValueError: {e}")
        return jsonify({"error": str(e)}), 500
    except Exception as e:
        print(f"Error in File Uploading: {e}")
        logging.error(f"Error: {e}")
        return jsonify({"error": "Error File Uploading."}), 500

try:
    if __name__ == "__main__":
        feature.run(debug = False) # disable debug to 'False' in security of sensitive data or inforamtion.

except ValueError as e:
    print(f"ValueError: {e}")
    logging.error(f"ValueError: {e}")
    jsonify({"error": str(e)}), 500
except Exception as e:
    print(f"Unknown Error: {e}")
    logging.error(f"Error: {e}")
    raise ValueError("Unknown Error occured during Flask App Startup.")




