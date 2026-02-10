from flask import jsonify # type: ignore
import logging
import cv2 as c
import numpy as np
from dotenv import load_dotenv # type: ignore
import tensorflow as tf # type: ignore

import efficientnet.tfkeras as efn # type: ignore

# adding AI learning component.
from tensorflow.keras.applications import ResNet50 # type: ignore
from tensorflow.keras.applications.resnet50 import preprocess_input # type: ignore

from sklearn.cluster import KMeans # type: ignore
from sklearn.metrics.pairwise import cosine_similarity # type: ignore

# more features for color detection and matching.
from colormath.color_objects import sRGBColor, LabColor # type: ignore
from colormath.color_conversions import convert_color # type: ignore
from colormath.delta_e import delta_e_ciede2000 # type: ignore


# loading environment variables from .env file.
load_dotenv()

# creating a logger for information.
logging.basicConfig(level=logging.INFO, format="%(asctime)s - %(levelname)s - %(message)s")


# load feature extraction model globally.
try:
    # validating the model.
    try:
        efficientNetB0_model = efn.EfficientNetB0(weights='imagenet', include_top=False, pooling='avg')
        print("Pretrained EfficientNetB0 Model loaded successfully for feature extraction!")
        
    except ValueError as e:
        print(f"EfficientNetB0 ValueError: {e}")
        logging.error(f"EfficientNetB0 ValueError: {e}")
        efficientNetB0_model = None
    except Exception as e:
        print(f"EfficientNetB0 Error in loading model: {e}")
        logging.error(f"EfficientNetB0 Error: {e}")
        efficientNetB0_model = None
        
except ValueError as e:
    print(f"EfficientNetB0 ValueError: {e}")
    logging.error(f"EfficientNetB0 ValueError: {e}")
    jsonify({"error": str(e)}), 500
except Exception as e:
    print(f"Unknown EfficientNetB0 Error: {e}")
    logging.error(f"EfficientNetB0 Error: {e}")
    raise ValueError("Unknown EfficientNetB0 Error occured.")

# function for pretraining CNN (i.e. EfficientNetB0).
def load_feature_extraction_model():
    if efficientNetB0_model is None:
        raise ValueError("Error in loading EfficientNetB0 model.")
    return efficientNetB0_model

# pre-processing image through different formatting.
def preprocess_image_efficientNetB0(image):
    # validating image processing.
    try:
        # validating image resizing.
        if image is None or image.shape != (244, 244, 3):
            raise ValueError("Invalid EfficientNetB0 Image Dimensions.")

        # image resizing, normalzing and expanding.
        img_resized = tf.image.resize(image, (224, 224))
        img_normalized = preprocess_input(img_resized)
        img_expanded = np.expand_dims(img_normalized, axis=0)
        
        return img_expanded
    
    except ValueError as e:
        print(f"EfficientNetB0 ValueError: {e}")
        logging.error(f"EfficientNetB0 ValueError: {e}")
        return None
    except Exception as e:
        print(f"EfficientNetB0 Error in Image Processing: {e}")
        logging.error(f"EfficientNetB0 Error: {e}")
        return None

def extract_features_efficientNetB0(image, model):
    try:
        # processing the image before extracting the features.
        processed_input = preprocess_image_efficientNetB0(image)
        if processed_input is None:
            return None
        
        features = model.predict(processed_input)
        return features.flatten()
        
    except ValueError as e:
        print(f"EfficientNetB0 ValueError: {e}")
        logging.error(f"EfficientNetB0 ValueError: {e}")
        return None
    except Exception as e:
        print(f"EfficientNetB0 Error in Image Processing: {e}")
        logging.error(f"EfficientNetB0 Error: {e}")
        return None




# function to predicting the accessory whether image matches.
def predict_accessory(image, model, confidence_threshold=0.5):
    # validating predictions.
    try:
        # predicting image.
        predicted_model = preprocess_image_efficientNetB0(image)
        predictions = model.predict(predicted_model)      
        predicted_class = np.argmax(predictions, axis=-1) # if model outputs a class probability.
        confidence = np.max(predictions) # create score of confidence.
        
        # binary classification with 1s or 0s for match or not match respectively.
        if confidence >= confidence_threshold:
            return predicted_class, 1, confidence # Match
        else:
            return predicted_class, 0, confidence # No Match
    
    except ValueError as e:
        print(f"ValueError: {e}")
        logging.error(f"ValueError: {e}")
        return None
    except Exception as e:
        print(f"Error in Predicting Accessory Image: {e}")
        logging.error(f"Error: {e}")
        return None


# function to predicting the outfit whether image matches.
def predict_outfit(image, model):
    # validating predictions.
    try:       
        return predict_accessory(image, model)
    
    except ValueError as e:
        print(f"ValueError: {e}")
        logging.error(f"ValueError: {e}")
        return None
    except Exception as e:
        print(f"Error in Predicting Outfit Image: {e}")
        logging.error(f"Error: {e}")
        return None
    

def extract_main_colors(image, k = 5):
    # validating color extractions.
    try:
        # read the image.
        img_col = c.imread(image)
        if img_col is None:
            return None
        # accept the image with colors.
        img_col = c.cvtColor(image, c.COLOR_BGR2RGB)
        # reshape image into 2D array of pixels.
        pixels = img_col.reshape(-1, 3)
        # KMeans clustering for the dominant colors.
        kmeans = KMeans(n_clusters=k, random_state=0, n_init="auto")
        kmeans.fit(pixels)
        # compiling all the data of the pixels.
        extract_dominant_colors = kmeans.cluster_centers_.astype(int).tolist()
        
        return extract_dominant_colors

    except ValueError as e:
        print(f"ValueError: {e}")
        logging.error(f"ValueError: {e}")
        return None
    except Exception as e:
        print(f"Error in Matching Outfits with Accessories: {e}")
        logging.error(f"Error: {e}")
        return None

def matching_colors_between_outfits_and_accessories(accessory_colors, outfit_colors, threshold=5):
    # validating the matching.
    try:
        for accessory_color in accessory_colors:
            for outfit_color in outfit_colors:
                # calcuating the euclidean distance between colors.
                distance = np.linalg.norm(accessory_color - outfit_color)
                if distance < threshold:
                    return True
                        
        return False
    
    except ValueError as e:
        print(f"ValueError: {e}")
        logging.error(f"ValueError: {e}")
        return None
    except Exception as e:
        print(f"Error in Matching Outfits with Accessories: {e}")
        logging.error(f"Error: {e}")
        return None

def find_closest_colors(accessory_colors, outfit_colors, delta_e_threshold=30):
    # validating the finding of closest colors.
    try:
        if accessory_colors is None or outfit_colors is None:
            return False, {}
        color_differences = {}
        match_found = False
        
        # finding the closest colors for each accessory compared to each outfit.
        for accessory_color in accessory_colors:
            min_delta_e = float("inf")
            closest_outfit_color = None
            
            for outfit_color in outfit_colors:
                delta_e = calculate_delta_e(accessory_color, outfit_color)
                
                if delta_e < min_delta_e:
                    min_delta_e = delta_e
                    closest_outfit_color = outfit_color
                    
            color_differences[tuple(accessory_color)] = {"closest color": closest_outfit_color, "delta e": min_delta_e}
            if min_delta_e < delta_e_threshold:
                match_found = True
        
        return match_found, color_differences
    
    except ValueError as e:
        print(f"ValueError: {e}")
        logging.error(f"ValueError: {e}")
        return None, None
    except Exception as e:
        print(f"Error in Finding closest colors: {e}")
        logging.error(f"Error: {e}")
        return None, None
    
def match_given_colors(accessory_colors, outfit_colors, delta_e_threshold=30):
    # validating the matching of given colors.
    try:
        if not accessory_colors or not outfit_colors:
            return False, {}
        overall_min_delta_e = float("inf")
        overall_closest_outfit_color = None
        
        closest_matches = {}
        
        # finding the closest colors for each accessory compared to each outfit.
        for accessory_color in accessory_colors:
            current_min_delta_e = float("inf")
            current_closest_outfit_color = None
            
            for outfit_color in outfit_colors:
                delta_e = calculate_delta_e(accessory_color, outfit_color)
                
                if delta_e < current_min_delta_e:
                    current_min_delta_e = delta_e
                    current_closest_outfit_color = outfit_color
                    
            closest_matches[tuple(accessory_color)] = {
                "current closest color": current_closest_outfit_color, 
                "current delta e": current_min_delta_e
            }
            
            if current_min_delta_e < overall_min_delta_e:
                current_min_delta_e = delta_e
                overall_closest_outfit_color = current_closest_outfit_color
                
        match_found = any(data["delta e"] < delta_e_threshold for data in closest_matches.values())
        
        return match_found, {"closest matches": closest_matches, 
                             "overall closest outfit color": overall_closest_outfit_color, 
                             "overall min delta e": overall_min_delta_e
                            }
    
    except ValueError as e:
        print(f"ValueError: {e}")
        logging.error(f"ValueError: {e}")
        return None, None, None
    except Exception as e:
        print(f"Error in Matching the colors: {e}")
        logging.error(f"Error: {e}")
        return None, None, None

def compare_feature_vectors(feature_vector_1, feature_vector_2, threshold=0.8):
    # validating the comparsion of feature vectors.
    try:
        if feature_vector_1 is None or feature_vector_2 is None:
            return False, 0.0
    
        similarity = cosine_similarity(feature_vector_1.reshape(1, -1), feature_vector_2.reshape(1, -1))[0][0]
        return similarity >= threshold, similarity
    
    except ValueError as e:
        print(f"ValueError: {e}")
        logging.error(f"ValueError: {e}")
        return None
    except Exception as e:
        print(f"Error in Comparing the feature vectors: {e}")
        logging.error(f"Error: {e}")
        return None

def calculate_delta_e(rgb1, rgb2):
    # validating the calucation with delta e.
    try:
        # checkign any colors.
        color_1_rgb = sRGBColor(rgb1[0]/255.0, rgb1[1]/255.0, rgb1[2]/255.0)
        color_2_rgb = sRGBColor(rgb2[0]/255.0, rgb2[1]/255.0, rgb2[2]/255.0)
        # converting colors.
        color_1_lab = convert_color(color_1_rgb, LabColor)
        color_2_lab = convert_color(color_2_rgb, LabColor)
        
        # calucation with delta e.
        delta_e_calculate = delta_e_ciede2000(color_1_lab, color_2_lab)
        return delta_e_calculate
        
    except ValueError as e:
        print(f"Delta E ValueError: {e}")
        logging.error(f"Delta E ValueError: {e}")
        return float("inf")
    except Exception as e:
        print(f"Error in Calculating Delta E: {e}")
        logging.error(f"Delta E Error: {e}")
        return float("inf")




