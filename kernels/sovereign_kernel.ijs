NB. sovereign_kernel.ijs
NB. Pure J array-language kernel for Radix-scaled residual folds and explicit DAG reductions

NB. Exact integer matrix multiplication (Dot product)
matmul =: +/ . *

NB. Forward array reduction (Sum over vector/matrix)
reduce_sum =: +/

NB. Radix-scaled projection fold
NB. y is the integer residual vector; projects against scaled base 10
radix_project =: 3 : 0
  weights =. y
  +/ weights * 10 ^ i. # weights
)

NB. Explicit backward DAG node computation
NB. x is the upstream gradient, y is the forward activation
NB. Computes exact gradient update matrix
backward_dag =: 4 : 0
  gradient =. x
  activation =. y
  gradient matmul |: activation
)

NB. Single step integer evaluation returning updated weights and max absolute error
NB. y is a boxed array: (Weights ; Input_X ; Target_Y ; LearningRate)
evaluate_step =: 3 : 0
  'W X Y_t LR' =. y
  
  Y_pred =. W matmul X
  error =. Y_pred - Y_t
  
  grad =. error backward_dag X
  W_new =. W - LR * grad
  
  max_error =. >./ | , error
  
  W_new ; max_error
)
