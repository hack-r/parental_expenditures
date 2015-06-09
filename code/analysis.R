# ============================================================================
# Name        : analysis.R
# Author      : Jason D. Miller
# Copyright   : (c) 2015, Please give a citation if you use this code
# Description : Descriptive statistics and econometric model for 
#                parent_expenditure.R
# ============================================================================

# Descriptive Statistics --------------------------------------------------


# Double Hurdle Model -----------------------------------------------------
# Cragg's Double Hurdle Model
## The dist option controls if Tobin or Cragg's model is estimated
cragg.stage1 <- mhurdle(durable ~ age | quant | 0, tobin, dist = "l")
cragg.stage2 <- mhurdle(durable ~ 0 | quant | age, tobin, dist = "l")

# Vuong test for strictly non-nested models
vuongtest(cragg.stage1, cragg.stage2)
