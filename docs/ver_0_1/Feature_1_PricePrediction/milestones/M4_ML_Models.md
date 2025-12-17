# Milestone 4: ML Model Development & Training

**Duration:** Week 4-6 (12 working days)
**Team:** Data Science (2 data scientists)
**Dependencies:** M3 (Feature engineering must be working)
**Status:** Not Started

---

## Objective

Develop, train, and validate two LSTM-based prediction models: one for normal trading days (98% of data) and one for earnings days (2% of data). Models must achieve target accuracy (MAE <1.5% and <2.5% respectively) and be optimized for production inference with ONNX Runtime.

---

## Success Criteria

- ✅ Normal Day Model: MAE <1.5% on validation set
- ✅ Earnings Day Model: MAE <2.5% on validation set
- ✅ Models exported to ONNX format
- ✅ Inference latency: <20ms per batch (128 symbols) on GPU
- ✅ Models versioned and stored with metadata
- ✅ Uncertainty quantification implemented (MC Dropout)
- ✅ Backtesting framework operational

---

## Task List

### 1. Data Preparation & Collection
**Status:** Not Started

- [ ] **T1.1** - Collect historical training data
  - [ ] Fetch 5 years of historical data for 1,000 symbols (subset for MVP)
  - [ ] Use Yahoo Finance API for OHLCV data
  - [ ] Store raw data in TimescaleDB
  - [ ] Validate data completeness (no large gaps)
  - [ ] Document data collection process
  - **Assigned to:** Data Scientist 1
  - **Estimated time:** 6 hours
  - **Blocked by:** M3 completion

- [ ] **T1.2** - Generate historical features
  - [ ] Use FeatureStore backfill utility to compute all 20 features
  - [ ] Generate features for entire 5-year period
  - [ ] Store in `feature_history` table
  - [ ] Validate feature quality (no excessive NaN)
  - [ ] Create feature statistics report
  - **Assigned to:** Data Scientist 1
  - **Estimated time:** 8 hours
  - **Blocked by:** T1.1

- [ ] **T1.3** - Label data (target variable)
  - [ ] Compute next-day return: (P_{t+1} / P_t) - 1
  - [ ] Handle missing labels (weekends, holidays)
  - [ ] Validate label distribution (check for outliers)
  - [ ] Split into normal days vs earnings days
  - **Assigned to:** Data Scientist 1
  - **Estimated time:** 4 hours
  - **Blocked by:** T1.2

- [ ] **T1.4** - Create train/validation/test splits
  - [ ] Time-based split: 70% train, 15% validation, 15% test
  - [ ] Ensure no data leakage (chronological order)
  - [ ] Balance splits across symbols
  - [ ] Document split dates and statistics
  - **Assigned to:** Data Scientist 1
  - **Estimated time:** 3 hours
  - **Blocked by:** T1.3

---

### 2. Exploratory Data Analysis (EDA)
**Status:** Not Started

- [ ] **T2.1** - Analyze feature distributions
  - [ ] Plot histograms for all 20 features
  - [ ] Identify skewness and outliers
  - [ ] Check for multicollinearity (correlation matrix)
  - [ ] Document feature characteristics
  - **Assigned to:** Data Scientist 2
  - **Estimated time:** 4 hours
  - **Blocked by:** T1.2

- [ ] **T2.2** - Analyze target variable (returns)
  - [ ] Plot distribution of next-day returns
  - [ ] Identify regime changes (high volatility periods)
  - [ ] Compare normal days vs earnings days distributions
  - [ ] Document return statistics (mean, std, skewness)
  - **Assigned to:** Data Scientist 2
  - **Estimated time:** 3 hours
  - **Blocked by:** T1.3

- [ ] **T2.3** - Feature importance analysis
  - [ ] Train baseline model (XGBoost or Random Forest)
  - [ ] Extract feature importances
  - [ ] Identify top 10 predictive features
  - [ ] Document findings for model development
  - **Assigned to:** Data Scientist 2
  - **Estimated time:** 4 hours
  - **Blocked by:** T2.1

---

### 3. Normal Day Model Development
**Status:** Not Started

- [ ] **T3.1** - Design Normal Day model architecture
  - [ ] Input layer: 20 features
  - [ ] Hidden layers: Dense(64) → Dropout(0.3) → Dense(32) → Dropout(0.2) → Dense(16)
  - [ ] Output layer: 1 neuron (predicted return)
  - [ ] Activation: ReLU for hidden, linear for output
  - [ ] Document architecture diagram
  - **Assigned to:** Data Scientist 1
  - **Estimated time:** 3 hours
  - **Blocked by:** T2.3

- [ ] **T3.2** - Implement Normal Day model in TensorFlow/Keras
  - [ ] Create model class with configurable hyperparameters
  - [ ] Implement custom loss function (MSE with outlier robustness)
  - [ ] Implement training loop with callbacks
  - [ ] Add early stopping (patience=10)
  - [ ] Add model checkpointing (save best model)
  - **Assigned to:** Data Scientist 1
  - **Estimated time:** 6 hours
  - **Blocked by:** T3.1

- [ ] **T3.3** - Train Normal Day model
  - [ ] Use 98% of normal day data
  - [ ] Optimizer: Adam (lr=0.001)
  - [ ] Batch size: 64
  - [ ] Epochs: 50 (with early stopping)
  - [ ] Monitor validation MAE
  - [ ] Save training history (loss curves)
  - **Assigned to:** Data Scientist 1
  - **Estimated time:** 8 hours (includes experiments)
  - **Blocked by:** T3.2

- [ ] **T3.4** - Hyperparameter tuning (Normal Day)
  - [ ] Grid search or random search on: learning rate, dropout, layer sizes
  - [ ] Use validation set for tuning
  - [ ] Document best hyperparameters
  - [ ] Retrain with best config
  - **Assigned to:** Data Scientist 1
  - **Estimated time:** 10 hours
  - **Blocked by:** T3.3

- [ ] **T3.5** - Validate Normal Day model
  - [ ] Evaluate on test set (15% holdout)
  - [ ] Compute MAE, RMSE, R²
  - [ ] Check if MAE <1.5% (target)
  - [ ] Analyze error distribution
  - [ ] Create validation report
  - **Assigned to:** Data Scientist 1
  - **Estimated time:** 4 hours
  - **Blocked by:** T3.4

---

### 4. Earnings Day Model Development
**Status:** Not Started

- [ ] **T4.1** - Design Earnings Day model architecture
  - [ ] Input layer: 37 features (20 technical + 17 earnings)
  - [ ] Hidden layers: Dense(64) → Dropout(0.3) → Dense(32) → Dropout(0.2) → Dense(16)
  - [ ] Output layer: 1 neuron (predicted return)
  - [ ] Same architecture as Normal Day for consistency
  - [ ] Document architecture diagram
  - **Assigned to:** Data Scientist 2
  - **Estimated time:** 2 hours
  - **Blocked by:** T3.1

- [ ] **T4.2** - Collect earnings-specific features
  - [ ] Extract EPS surprise, revenue surprise from historical data
  - [ ] Compute fundamental metrics (margins, growth rates)
  - [ ] Compute historical earnings patterns (avg return after earnings)
  - [ ] Validate earnings feature completeness
  - [ ] Note: Transcript sentiment deferred to M6 (use placeholder 0)
  - **Assigned to:** Data Scientist 2
  - **Estimated time:** 8 hours
  - **Blocked by:** T1.3

- [ ] **T4.3** - Implement Earnings Day model in TensorFlow/Keras
  - [ ] Create model class (similar to Normal Day)
  - [ ] Adjust input layer for 37 features
  - [ ] Implement sample weighting (10x weight for earnings samples)
  - [ ] Add class for handling sparse earnings data
  - **Assigned to:** Data Scientist 2
  - **Estimated time:** 5 hours
  - **Blocked by:** T4.1, T4.2

- [ ] **T4.4** - Train Earnings Day model
  - [ ] Use 2% of earnings day data
  - [ ] Optimizer: Adam (lr=0.001)
  - [ ] Batch size: 32 (smaller due to less data)
  - [ ] Epochs: 100 (more epochs for smaller dataset)
  - [ ] Apply sample weighting to balance importance
  - [ ] Monitor validation MAE
  - **Assigned to:** Data Scientist 2
  - **Estimated time:** 8 hours (includes experiments)
  - **Blocked by:** T4.3

- [ ] **T4.5** - Hyperparameter tuning (Earnings Day)
  - [ ] Tune: learning rate, dropout, sample weight multiplier
  - [ ] Use validation set for tuning
  - [ ] Address overfitting (small dataset challenge)
  - [ ] Document best hyperparameters
  - **Assigned to:** Data Scientist 2
  - **Estimated time:** 10 hours
  - **Blocked by:** T4.4

- [ ] **T4.6** - Validate Earnings Day model
  - [ ] Evaluate on test set (earnings days only)
  - [ ] Compute MAE, RMSE, R²
  - [ ] Check if MAE <2.5% (target)
  - [ ] Analyze error by earnings surprise magnitude
  - [ ] Create validation report
  - **Assigned to:** Data Scientist 2
  - **Estimated time:** 4 hours
  - **Blocked by:** T4.5

---

### 5. Uncertainty Quantification
**Status:** Not Started

- [ ] **T5.1** - Implement MC Dropout for uncertainty
  - [ ] Enable dropout during inference
  - [ ] Run 20 forward passes per prediction
  - [ ] Compute mean (prediction) and std (uncertainty σ)
  - [ ] Compute percentiles (p10, p50, p90)
  - [ ] Validate uncertainty calibration
  - **Assigned to:** Data Scientist 1
  - **Estimated time:** 6 hours
  - **Blocked by:** T3.5, T4.6

- [ ] **T5.2** - Calibrate uncertainty estimates
  - [ ] Check if 80% of actuals fall within 80% confidence interval
  - [ ] Adjust dropout rates if needed
  - [ ] Document calibration process
  - [ ] Create calibration plots
  - **Assigned to:** Data Scientist 1
  - **Estimated time:** 4 hours
  - **Blocked by:** T5.1

---

### 6. Model Export & Optimization
**Status:** Not Started

- [ ] **T6.1** - Export models to ONNX format
  - [ ] Convert Normal Day model to ONNX using tf2onnx
  - [ ] Convert Earnings Day model to ONNX
  - [ ] Validate ONNX models produce same outputs as Keras
  - [ ] Save ONNX files with version suffix (e.g., `lstm_normal_v2.1.onnx`)
  - **Assigned to:** Data Scientist 1
  - **Estimated time:** 4 hours
  - **Blocked by:** T5.2

- [ ] **T6.2** - Optimize ONNX models for inference
  - [ ] Apply ONNX optimizer (remove unused nodes)
  - [ ] Quantize to float16 (if GPU supports mixed precision)
  - [ ] Benchmark inference latency (target: <20ms per batch)
  - [ ] Document optimization steps
  - **Assigned to:** Data Scientist 1
  - **Estimated time:** 4 hours
  - **Blocked by:** T6.1

- [ ] **T6.3** - Create feature scalers (normalization)
  - [ ] Fit StandardScaler on training data (20 features)
  - [ ] Fit StandardScaler on training data (37 features)
  - [ ] Save scalers as pickle files
  - [ ] Document scaler usage
  - **Assigned to:** Data Scientist 2
  - **Estimated time:** 2 hours
  - **Blocked by:** T3.5, T4.6

---

### 7. Model Versioning & Metadata
**Status:** Not Started

- [ ] **T7.1** - Create model metadata files
  - [ ] Create `metadata.json` for each model
  - [ ] Include: training date, MAE, RMSE, R², feature list, scaler path
  - [ ] Include: training data date range, symbol count
  - [ ] Include: hyperparameters used
  - **Assigned to:** Data Scientist 1
  - **Estimated time:** 2 hours
  - **Blocked by:** T6.3

- [ ] **T7.2** - Set up model versioning system
  - [ ] Store models in `/models/{model_type}/{version}/` structure
  - [ ] Tag with semantic versioning (v2.1, v2.2, etc.)
  - [ ] Create model registry (simple JSON or database)
  - [ ] Document versioning process
  - **Assigned to:** Data Scientist 1
  - **Estimated time:** 3 hours
  - **Blocked by:** T7.1

- [ ] **T7.3** - Upload models to persistent storage
  - [ ] Store models in S3 or local volume (for Docker)
  - [ ] Create download script for production deployment
  - [ ] Verify model integrity (checksums)
  - **Assigned to:** DevOps Lead
  - **Estimated time:** 2 hours
  - **Blocked by:** T7.2

---

### 8. Backtesting Framework
**Status:** Not Started

- [ ] **T8.1** - Design backtesting framework
  - [ ] Define backtesting metrics (MAE, directional accuracy, Sharpe)
  - [ ] Create backtesting script that simulates production
  - [ ] Support walk-forward testing
  - [ ] Document backtesting methodology
  - **Assigned to:** Data Scientist 2
  - **Estimated time:** 4 hours
  - **Blocked by:** T3.5

- [ ] **T8.2** - Implement backtesting engine
  - [ ] Loop through test set chronologically
  - [ ] Make predictions using features (no future data)
  - [ ] Compute returns and errors
  - [ ] Track cumulative performance
  - [ ] Generate backtesting report
  - **Assigned to:** Data Scientist 2
  - **Estimated time:** 6 hours
  - **Blocked by:** T8.1

- [ ] **T8.3** - Run comprehensive backtest
  - [ ] Backtest Normal Day model on 1 year of test data
  - [ ] Backtest Earnings Day model on earnings events
  - [ ] Analyze performance by market conditions (bull, bear, sideways)
  - [ ] Document findings and edge cases
  - **Assigned to:** Data Scientist 2
  - **Estimated time:** 4 hours
  - **Blocked by:** T8.2

---

### 9. Model Inference Testing
**Status:** Not Started

- [ ] **T9.1** - Set up ONNX Runtime environment
  - [ ] Install ONNX Runtime with GPU support
  - [ ] Configure CUDA providers
  - [ ] Test GPU availability
  - [ ] Document setup instructions
  - **Assigned to:** DevOps Lead
  - **Estimated time:** 3 hours
  - **Blocked by:** M1 completion

- [ ] **T9.2** - Create inference wrapper class
  - [ ] Create `ModelInference` class for ONNX models
  - [ ] Implement `predict(features)` method
  - [ ] Implement `predict_batch(features_list)` method
  - [ ] Handle model loading and caching
  - [ ] Add error handling
  - **Assigned to:** Data Scientist 1
  - **Estimated time:** 5 hours
  - **Blocked by:** T6.2, T9.1

- [ ] **T9.3** - Benchmark inference performance
  - [ ] Test single prediction latency (target: <5ms)
  - [ ] Test batch prediction latency (128 symbols, target: <20ms)
  - [ ] Test GPU vs CPU performance
  - [ ] Test memory usage
  - [ ] Document benchmark results
  - **Assigned to:** Data Scientist 1
  - **Estimated time:** 3 hours
  - **Blocked by:** T9.2

- [ ] **T9.4** - Validate inference accuracy
  - [ ] Compare ONNX predictions with Keras predictions
  - [ ] Ensure numerical differences <1e-5
  - [ ] Test with edge case inputs (zeros, extremes)
  - [ ] Document validation process
  - **Assigned to:** Data Scientist 1
  - **Estimated time:** 2 hours
  - **Blocked by:** T9.3

---

### 10. Monitoring & Model Drift Detection
**Status:** Not Started

- [ ] **T10.1** - Design model monitoring strategy
  - [ ] Define metrics to track (MAE, prediction distribution)
  - [ ] Define drift detection thresholds
  - [ ] Plan for periodic retraining
  - [ ] Document monitoring plan
  - **Assigned to:** Data Scientist 2
  - **Estimated time:** 3 hours
  - **Blocked by:** T8.3

- [ ] **T10.2** - Implement prediction logging
  - [ ] Log all predictions with actuals (next day)
  - [ ] Store in TimescaleDB `model_predictions` table
  - [ ] Include: symbol, timestamp, predicted, actual, error
  - [ ] Enable rolling MAE calculation
  - **Assigned to:** Data Scientist 2
  - **Estimated time:** 4 hours
  - **Blocked by:** T10.1

- [ ] **T10.3** - Create model performance dashboard
  - [ ] Panel: Rolling 7-day MAE (line chart)
  - [ ] Panel: Prediction vs Actual scatter plot
  - [ ] Panel: Error distribution histogram
  - [ ] Panel: Inference latency
  - [ ] Add to Grafana
  - **Assigned to:** Data Scientist 2
  - **Estimated time:** 4 hours
  - **Blocked by:** T10.2

---

### 11. Documentation
**Status:** Not Started

- [ ] **T11.1** - Document model architecture
  - [ ] Create architecture diagrams (both models)
  - [ ] Document input/output specifications
  - [ ] Document training process
  - [ ] Document hyperparameters and rationale
  - **Assigned to:** Data Scientist 1
  - **Estimated time:** 4 hours
  - **Blocked by:** T7.2

- [ ] **T11.2** - Create model card (ML documentation)
  - [ ] Intended use and limitations
  - [ ] Training data description
  - [ ] Performance metrics
  - [ ] Ethical considerations
  - [ ] Model update policy
  - **Assigned to:** Data Scientist 2
  - **Estimated time:** 3 hours
  - **Blocked by:** T11.1

- [ ] **T11.3** - Create retraining runbook
  - [ ] How to collect new training data
  - [ ] How to retrain models
  - [ ] How to validate new models
  - [ ] How to deploy new model versions
  - **Assigned to:** Data Scientist 1
  - **Estimated time:** 3 hours
  - **Blocked by:** T11.2

---

## Deliverables

1. ✅ **Two trained models** - Normal Day and Earnings Day
2. ✅ **ONNX model files** - Optimized for inference
3. ✅ **Feature scalers** - Normalization parameters
4. ✅ **Model metadata** - Versioned with performance metrics
5. ✅ **Backtesting report** - Validation on test data
6. ✅ **Inference wrapper** - Production-ready prediction code
7. ✅ **Monitoring dashboard** - Model performance tracking
8. ✅ **Documentation** - Model cards, architecture, runbooks

---

## Risks & Mitigations

| Risk | Mitigation |
|------|------------|
| Normal Day model MAE >1.5% | Collect more data, add features, try ensemble methods |
| Earnings Day model MAE >2.5% | Use transfer learning from Normal Day, increase sample weighting |
| Insufficient earnings day data | Use data augmentation, reduce model complexity, accept higher MAE |
| Overfitting due to small dataset | Use regularization (dropout, L2), cross-validation, early stopping |
| ONNX conversion issues | Test early, use tf2onnx official converter, validate outputs |
| GPU inference slower than expected | Optimize batch size, use TensorRT, profile GPU utilization |

---

## Acceptance Criteria

- [ ] Normal Day model achieves MAE <1.5% on test set
- [ ] Earnings Day model achieves MAE <2.5% on test set
- [ ] ONNX models produce identical predictions to Keras models
- [ ] Batch inference latency <20ms for 128 symbols on GPU
- [ ] Uncertainty estimates are calibrated (80% actuals in 80% CI)
- [ ] Models versioned and stored with complete metadata
- [ ] Backtesting shows consistent performance over 1-year test period
- [ ] Inference wrapper tested and production-ready
- [ ] Model monitoring dashboard operational
- [ ] Documentation complete and reviewed

---

## Definition of Done

- [ ] All tasks marked as "Done"
- [ ] Both models trained and validated
- [ ] Performance targets met (MAE)
- [ ] Models exported to ONNX and benchmarked
- [ ] Backtesting completed with satisfactory results
- [ ] Code reviewed and merged to `develop` branch
- [ ] Documentation complete (model cards, architecture, runbooks)
- [ ] Demo completed showing predictions vs actuals
- [ ] Data Science Lead sign-off

---

**Milestone Owner:** Data Scientist 1
**Review Date:** End of Week 6
**Next Milestone:** M5 - Prediction Pipeline & Routing

[End of Milestone 4]
