# NutriLeaf: A Hierarchical Hybrid CNN–Transformer Framework for Vegetable Crop Nutrient Deficiency Classification Using Leaf Images

## Project Overview
NutriLeaf is an advanced agricultural technology solution designed to detect nutrient deficiencies in vegetable crops using leaf images. The core of this system is a hybrid Artificial Intelligence (AI) framework that integrates Convolutional Neural Networks (CNN) and Transformer architectures. This approach leverages the spatial feature extraction capabilities of CNNs alongside the global contextual understanding of Transformers to deliver highly accurate deficiency classifications.

## System Concept
The system operates as an end-to-end diagnostic tool for farmers and agricultural experts. A user captures or uploads an image of a vegetable crop leaf exhibiting signs of stress or poor health. The system processes the image through a specialized machine learning pipeline to identify the specific nutrient deficiency. Once classified, the system outputs the identified deficiency along with actionable fertilizer recommendations to mitigate the issue.

## System Architecture
NutriLeaf employs a standard 3-tier architecture to ensure scalability, maintainability, and a seamless user experience:

*   **Frontend**: A mobile application built with Flutter. It provides the user interface for capturing images, viewing results, and managing scan history.
*   **Backend**: A RESTful API server developed using FastAPI. It handles incoming requests from the mobile app, manages the integration with the machine learning models, and processes the classification logic.
*   **Database**: Supabase (PostgreSQL with integrated Authentication) is used to securely store user data, authentication credentials, scan histories, and feedback logs.

## Machine Learning Pipeline
The core classification process follows a structured pipeline:

1.  **Image Input**: The system receives a high-resolution leaf image from the frontend.
2.  **Preprocessing**: The image undergoes normalization, resizing, and augmentation to prepare it for analysis.
3.  **YOLOv8 Detection**: A YOLOv8 model performs object detection and localization to isolate the exact leaf region, cropping out background noise.
4.  **CNN–Transformer Classification**: The cropped leaf image is fed into a MobileViT (CNN–Transformer) model. This hybrid architecture extracts both local textures (e.g., specific discoloration patterns) and global structures (e.g., overall leaf shape).
5.  **Output Generation**: The model outputs a specific nutrient deficiency label along with a statistical confidence score.

## Application Flow (User Perspective)
1.  **Login/Register**: Users authenticate via the Supabase integration.
2.  **Select Crop**: The user selects the specific vegetable crop they are evaluating.
3.  **Capture/Upload Image**: The user takes a new photo using the device camera or selects an existing image from their gallery.
4.  **Preview Image**: The selected image is previewed to ensure clarity.
5.  **Scan Leaf**: The user initiates the analysis process.
6.  **View Result**: The application displays the identified nutrient deficiency and the model's confidence score.
7.  **View Fertilizer Recommendation**: Actionable treatment recommendations corresponding to the diagnosed deficiency are provided.
8.  **Save to History**: The scan record is saved to the user's personal history log.
9.  **Feedback**: The user can provide feedback on the accuracy of the diagnosis (Correct/Incorrect) and the utility of the recommendation (Helpful/Not Helpful).

## Backend Flow
1.  **API Request**: The FastAPI backend receives the image and metadata via a secure API endpoint.
2.  **Model Inference**: The backend routes the image through the YOLOv8 and MobileViT models for processing.
3.  **Result Processing**: The classification label, confidence score, and corresponding recommendations are aggregated.
4.  **JSON Response**: The backend returns a structured JSON payload to the Flutter application for rendering.

## Tech Stack
*   **Frontend**: Flutter
*   **Backend**: FastAPI
*   **Database**: Supabase (PostgreSQL + Auth)
*   **Object Detection**: YOLOv8
*   **Classification**: MobileViT

## Key Features
*   Precision leaf-based detection
*   Support for multiple vegetable crop varieties
*   Accurate nutrient deficiency classification
*   Actionable fertilizer recommendations
*   Comprehensive scan history tracking
*   Integrated user feedback system for continuous improvement

## Project Status
NutriLeaf is currently under development. The application infrastructure is being established, and the machine learning models are actively undergoing training and validation phases.

## Future Improvements
*   Expansion to support a wider variety of vegetable crops.
*   Inclusion of additional nutrient deficiency classes and disease detection.
*   Further optimization of model architecture for higher accuracy and faster inference.
*   Implementation of offline capability for on-device inference in areas with limited connectivity.
