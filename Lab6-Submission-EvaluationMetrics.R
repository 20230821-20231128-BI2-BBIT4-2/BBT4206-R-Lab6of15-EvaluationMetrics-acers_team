#20231019
# STEP 1. Install and Load the Required Packages ----
## ggplot2 ----
if (require("ggplot2")) {
  require("ggplot2")
} else {
  install.packages("ggplot2", dependencies = TRUE,
                   repos = "https://cloud.r-project.org")
}

## caret ----
if (require("caret")) {
  require("caret")
} else {
  install.packages("caret", dependencies = TRUE,
                   repos = "https://cloud.r-project.org")
}

## mlbench ----
if (require("mlbench")) {
  require("mlbench")
} else {
  install.packages("mlbench", dependencies = TRUE,
                   repos = "https://cloud.r-project.org")
}

## pROC ----
if (require("pROC")) {
  require("pROC")
} else {
  install.packages("pROC", dependencies = TRUE,
                   repos = "https://cloud.r-project.org")
}

## dplyr ----
if (require("dplyr")) {
  require("dplyr")
} else {
  install.packages("dplyr", dependencies = TRUE,
                   repos = "https://cloud.r-project.org")
}

# 1. Accuracy and Cohen's Kappa ----
## 1.a. Load the dataset ----
library(readr)
heart_attack_dataset <- read_csv("data/heart_attack_dataset.csv")
View(heart_attack_dataset)
# data(heart_attack_dataset) 
# sapply(heart_attack_dataset, class) #datatypes of variables


## 1.b. Determine the Baseline Accuracy ----
heart_attack_dataset_freq <- heart_attack_dataset$class
cbind(frequency =
        table(heart_attack_dataset_freq),
      percentage = prop.table(table(heart_attack_dataset_freq)) * 100)

## 1.c. Split the dataset ----
# Define a 75:25 train:test data split of the dataset.
# That is, 75% of the original data will be used to train the model and
# 25% of the original data will be used to test the model.
train_index <- createDataPartition(heart_attack_dataset$class,
                                   p = 0.75,
                                   list = FALSE)
heart_attack_dataset_train <- heart_attack_dataset[train_index, ]
heart_attack_dataset_test <- heart_attack_dataset[-train_index, ]


## 1.d. Train the Model ----
# We apply the 5-fold cross validation resampling method
train_control <- trainControl(method = "cv", number = 5)


# `set.seed()` is a function that is used to specify a starting point for the
# random number generator to a specific value. This ensures that every time you
# run the same code, you will get the same "random" numbers.
set.seed(7) #you can use any values the point is to introduce the randomness 
class_model_glm <-
  train(class ~ ., data = heart_attack_dataset_train, method = "glm",
        metric = "Accuracy", trControl = train_control) #all other variables ~ .

## 1.e. Display the Model's Performance ----
### Option 1: Use the metric calculated by caret when training the model ----
print(class_model_glm)

# 2. RMSE, R Squared, and MAE ----
#THIS WILL NOT APPLY IN THIS SECTION. 

# 3. Area Under ROC Curve ----
## Area Under Receiver Operating Characteristic Curve (AUROC) or simply
## "Area Under Curve (AUC)" or "ROC" represents a model's ability to
## discriminate between two classes.

## 3.b. Determine the Baseline Accuracy ----
heart_attack_dataset_freq <- heart_attack_dataset$class
cbind(frequency =
        table(heart_attack_dataset_freq),
      percentage = prop.table(table(heart_attack_dataset_freq)) * 100)


## 3.c. Split the dataset ----
# Define an 80:20 train:test data split of the dataset.
train_index <- createDataPartition(heart_attack_dataset$class,
                                   p = 0.8,
                                   list = FALSE)
heart_attack_dataset_train <- heart_attack_dataset[train_index, ]
heart_attack_dataset_test <- heart_attack_dataset[-train_index, ]

## 3.d. Train the Model ----
# We apply the 10-fold cross validation resampling method
train_control <- trainControl(method = "cv", number = 10,
                              classProbs = TRUE,
                              summaryFunction = twoClassSummary)

# We then train a k Nearest Neighbours Model to predict the value of Diabetes
# (whether the patient will test positive/negative for diabetes).

set.seed(7)
class_model_knn <-
  train(class ~ ., data = heart_attack_dataset_train, method = "knn",
        metric = "ROC", trControl = train_control)

## 3.e. Display the Model's Performance ----
### Option 1: Use the metric calculated by caret when training the model ----
# The results show a ROC value of approximately 0.76 (the closer to 1,
# the higher the prediction accuracy) when the parameter k = 9
# (9 nearest neighbours).

print(class_model_knn)

### Option 2: Compute the metric yourself using the test dataset ----
#### Sensitivity and Specificity ----
predictions <- predict(class_model_knn, heart_attack_dataset_test[, 1:8])
# These are the values for diabetes that the
# model has predicted:
print(predictions)
confusion_matrix <-
  caret::confusionMatrix(predictions,
                         heart_attack_dataset_test[, 1:9]$class)

# We can see the sensitivity (≈ 0.86) and the specificity (≈ 0.60) below:
print(confusion_matrix)


#### AUC ----
# The type = "prob" argument specifies that you want to obtain class
# probabilities as the output of the prediction instead of class labels.
predictions <- predict(class_model_knn, heart_attack_dataset_test[, 1:8],
                       type = "prob")

# These are the class probability values for diabetes that the
# model has predicted:
print(predictions)

# "Controls" and "Cases": In a binary classification problem, you typically
# have two classes, often referred to as "controls" and "cases."
# These classes represent the different outcomes you are trying to predict.
# For example, in a medical context, "controls" might represent patients without
# a disease, and "cases" might represent patients with the disease.

# Setting the Direction: The phrase "Setting direction: controls < cases"
# specifies how you define which class is considered the positive class (cases)
# and which is considered the negative class (controls) when calculating
# sensitivity and specificity.
roc_curve <- roc(heart_attack_dataset_test$class, predictions$neg)

# Plot the ROC curve
plot(roc_curve, main = "ROC Curve for KNN Model", print.auc = TRUE,
     print.auc.x = 0.6, print.auc.y = 0.6, col = "blue", lwd = 2.5)


# 4. Logarithmic Loss (LogLoss) ----
########################### ----
## 4.a. Load the dataset ----
## 4.b. Train the Model ----
# We apply the 5-fold repeated cross validation resampling method
# with 3 repeats
train_control <- trainControl(method = "repeatedcv", number = 5, repeats = 3,
                              classProbs = TRUE,
                              summaryFunction = mnLogLoss)
set.seed(7)
# This creates a CART model. One of the parameters used by a CART model is "cp".
# "cp" refers to the "complexity parameter". It is used to impose a penalty to
# the tree for having too many splits. The default value is 0.01.
heart_model_cart <- train(class ~ ., data = heart_attack_dataset, method = "rpart",
                         metric = "logLoss", trControl = train_control)

## 4.c. Display the Model's Performance ----
### Option 1: Use the metric calculated by caret when training the model ----
# The results show that a cp value of ≈ 0 resulted in the lowest
# LogLoss value. The lowest logLoss value is ≈ 0.46.
print(heart_model_cart)


# References ----

## Kuhn, M., Wing, J., Weston, S., Williams, A., Keefer, C., Engelhardt, A., Cooper, T., Mayer, Z., Kenkel, B., R Core Team, Benesty, M., Lescarbeau, R., Ziem, A., Scrucca, L., Tang, Y., Candan, C., & Hunt, T. (2023). caret: Classification and Regression Training (6.0-94) [Computer software]. https://cran.r-project.org/package=caret # nolint ----

## Leisch, F., & Dimitriadou, E. (2023). mlbench: Machine Learning Benchmark Problems (2.1-3.1) [Computer software]. https://cran.r-project.org/web/packages/mlbench/index.html # nolint ----

## National Institute of Diabetes and Digestive and Kidney Diseases. (1999). Pima Indians Diabetes Dataset [Dataset]. UCI Machine Learning Repository. https://www.kaggle.com/datasets/uciml/pima-indians-diabetes-database # nolint ----

## Robin, X., Turck, N., Hainard, A., Tiberti, N., Lisacek, F., Sanchez, J.-C., Müller, M., Siegert, S., Doering, M., & Billings, Z. (2023). pROC: Display and Analyze ROC Curves (1.18.4) [Computer software]. https://cran.r-project.org/web/packages/pROC/index.html # nolint ----

## Wickham, H., François, R., Henry, L., Müller, K., Vaughan, D., Software, P., & PBC. (2023). dplyr: A Grammar of Data Manipulation (1.1.3) [Computer software]. https://cran.r-project.org/package=dplyr # nolint ----

## Wickham, H., Chang, W., Henry, L., Pedersen, T. L., Takahashi, K., Wilke, C., Woo, K., Yutani, H., Dunnington, D., Posit, & PBC. (2023). ggplot2: Create Elegant Data Visualisations Using the Grammar of Graphics (3.4.3) [Computer software]. https://cran.r-project.org/package=ggplot2 # nolint ----