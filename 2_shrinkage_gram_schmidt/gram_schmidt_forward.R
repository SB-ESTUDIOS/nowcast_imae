gram_schmidt_forward <- function(data, y_var, x_vars, 
                                 r2_threshold = 0.01, 
                                 max_vars = length(x_vars),
                                 verbose = TRUE) {
  
  # Extract data
  y <- data[[y_var]]
  X <- as.matrix(data[, x_vars, drop = FALSE])
  
  n <- length(y)
  
  # Storage
  selected_vars <- c()
  remaining_vars <- x_vars
  
  Z_selected <- NULL   # orthogonalized selected variables
  residual_current <- y-mean(y)
  
  results <- list()
  
  total_ss <- sum((y - mean(y))^2)
  rss_current <- sum(residual_current^2)
  
  step <- 1
  
  while (length(remaining_vars) > 0 && step <= max_vars) {
    
    if (verbose) {
      cat("\n", rep("=", 60), "\n")
      cat("STEP", step, "\n")
      cat(rep("=", 60), "\n")
    }
    
    best_var <- NULL
    best_corr <- 0
    best_Z <- NULL
    
    # Loop over remaining variables
    for (var in remaining_vars) {
      
      x_j <- data[[var]]
      
      # Orthogonalize
      if (is.null(Z_selected)) {
        Z_j <- x_j
      } else {
        ortho_model <- lm(x_j ~ Z_selected - 1)
        Z_j <- residuals(ortho_model)
      }
      # if (sd(residual_current) == 0) {
      #   print("residual_current has zero standard deviation")
      # }
      # 
      # if (sd(Z_j) == 0) {
      #   print("Z_j has zero standard deviation")
      # }
      # Compute correlation with residual
      corr <- abs(cor(residual_current, Z_j))
      
      if (!is.na(corr) && corr > best_corr) {
        best_corr <- corr
        best_var <- var
        best_Z <- Z_j
      }
    }
    
    if (is.null(best_var)) break
    
    # Regress residual on best_Z
    model <- lm(residual_current ~ best_Z)
    fitted_vals <- fitted(model)
    
    residual_new <- residual_current - fitted_vals
    
    rss_new <- sum(residual_new^2)
    
    # Incremental R2
    delta_r2 <- (rss_current - rss_new) / total_ss
    
    if (verbose) {
      cat("Selected variable:", best_var, "\n")
      cat("Correlation with residual:", round(best_corr, 4), "\n")
      cat("Incremental R2:", round(delta_r2, 6), "\n")
    }
    
    # Stopping rule
    if (delta_r2 < r2_threshold) {
      if (verbose) cat("Stopping: R2 gain below threshold\n")
      break
    }
    
    # Update sets
    selected_vars <- c(selected_vars, best_var)
    remaining_vars <- setdiff(remaining_vars, best_var)
    
    # Store orthogonalized variable
    if (is.null(Z_selected)) {
      Z_selected <- matrix(best_Z, ncol = 1)
    } else {
      Z_selected <- cbind(Z_selected, best_Z)
    }
    
    colnames(Z_selected) <- paste0("Z_", selected_vars)
    
    # Update residual
    residual_current <- residual_new
    rss_current <- rss_new
    
    # Store results
    results[[step]] <- list(
      step = step,
      variable = best_var,
      correlation = best_corr,
      delta_r2 = delta_r2,
      model = model
    )
    
    step <- step + 1
  }
  
  # Final model (using all selected orthogonalized variables)
  if (!is.null(Z_selected)) {
    final_model <- lm(y ~ Z_selected)
  } else {
    final_model <- NULL
  }
  
  return(list(
    selected_variables = selected_vars,
    results = results,
    final_model = final_model,
    Z = Z_selected
  ))
}