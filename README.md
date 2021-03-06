# Gaussian Belief Propagation Linear Systems Solver

![Build](https://github.com/mcosovic/GaussBP.jl/workflows/Build/badge.svg)

The solver provides the solution of the linear system of equations with/without Gaussian noise using belief propagation (BP) algorithm applied over the factor graph.

## The System Model
We observe a noisy linear system of equations with real coefficients and variables:

![equation](https://latex.codecogs.com/gif.latex?%5Ctextbf%7Bb%7D%20%3D%20%5Ctextbf%7Bf%7D%28%5Ctextbf%7Bx%7D%29%20&plus;%20%5Ctextbf%7Bu%7D)

where **x** is the vector of the state variables (i.e., unknowns), **f**(**x**) is the vector of linear functions, **b** is the vector of observation values and **u** is the vector of uncorrelated observation errors. Note that the linear system of equations represents an overdetermined system.

The solution can be obtained by solving linear weighted least-squares (WLS) problem:

![wls](https://latex.codecogs.com/gif.latex?%28%5Cmathbf%7BH%7D%5ET%5Cmathbf%7BW%7D%5Cmathbf%7BH%7D%29%5Cmathbf%7Bx%7D%20%3D%20%5Cmathbf%7BH%7D%5ET%20%5Cmathbf%7BW%7D%5Cmathbf%7Bb%7D)

where **H** is the Jacobian matrix of linear functions or the coefficient  matrix for our system, and **W** is a diagonal matrix containing inverses of observation variances.

Further, the solution to the problem can be found via maximization of the likelihood function which is defined via likelihoods of independent observations, and that can be efficiently solved utilizing factor graphs and the Gaussian belief propagation (BP) algorithm.

## Installation
The package requires Julia 1.2 and higher, to install `GaussBP`, you can run the following:
```
pkg> add https://github.com/mcosovic/GaussBP.jl
```

## Syntax
```
bp(DATA; max, damp, bump, prob, alpha, mean, variance, method, algorithm, wls, path)
```

## Input Arguments:
1. The input argument `DATA` can be given in formats:
    - HDF5:
      - `model.h5/H` - coefficient data `H::Array{Float64,2} = [row column coefficient]`;
      - `model.h5/b` - observation values `b::Array{Float64,1}`;
      - `model.h5/v` - observation variances `v::Array{Float64,1}`;
    - CSV:
      - `model.csv` - data with columns `row | column | coefficient | observation | variance`;

    Example systems located in `src/example`: `data33_14.h5`, `data897_300.h5`, `data3119_1354.h5`, `data5997_2000.h5`, `data7149_2000.h5` `data29997_10000.h5`, `data283803_70000.h5`, `data33_14.csv`, `data5997_2000.csv`

    Default setting: `DATA::String = "data33_14.h5"`

2. Design of Iteration Scheme:
    - `max` - the upper limit on BP iterations;
    - `damp` - applied randomized damping at the BP iteration;
    - `bump` - suspend the computation of variances at the BP iteration (in a usual scenario, variances converge much faster than means)

    Default settings: `max::Int64 = 30`, `damp::Int64 = 10`, `bump::Int64 = max`

3. Convergence Parameters:
    - `prob` - a Bernoulli random variable with probability "PROB" independently sampled for each mean value message from indirect factor node to a variable node, with values between 0 and 1;
    - `alpha` - the damped message is evaluated as a linear combination of the message from the previous and the current iteration, with weights "ALPH" and 1 - "ALPH", where "ALPH" is between 0 and 1;

    Default settings: `prob::Float64 = 0.6`, `alpha::Float64 = 0.4`

    Note: We use an improved BP algorithm that applies synchronous scheduling  with randomized damping. The randomized damping parameter pairs lead to a trade-off between the number of non-converging simulations and the rate of convergence. In general, for the selection of "PROB" and "ALPH" for which only a small fraction of messages are combined with their values in a previous iteration, and that is a case for "PROB" close to 0 or "ALPH" close to 1, we observe a large number of non-converging simulations.

4. Virtual Factor Nodes
    - `mean` - the mean value of virtual factor nodes;
    - `variance` - the variance value of the virtual factor nodes;

    Default settings: `mean::Float64 = 0.0`, `variance::Float64 = 1e5`

    Note: The virtual factor node is a singly-connected factor node used if the variable node x is not directly observed. In a usual scenario, without prior knowledge, the variance of virtual factor nodes tend to infinity.

5. Methods
    - `method = "passing"` - computes separately messages from factor and variable nodes;
    - `method = "recursion"` - computes jointly messages reduced to factor nodes (only for `algorithm = "sum"`);

    Default setting: `method::String = "passing"`

6. Algorithms
    - `algorithm = "sum"` - the belief propagation with simply summing messages;
    - `algorithm = "kahan"` - the belief propagation with Kahan-Babuska algorithm for summing variances;

    Default setting: `algorithm::String = "sum"`

7. Post-Processing Options:
    - `wls = "bultin"` - shows belief propagation evaluation vs. weighted least-squares using built-in linear system solver;
    - `wls = "lu"` - shows belief propagation evaluation vs. weighted least-squares using LU linear system solver;

8. Path Option:
    - `path` - path to the `DATA` file;

    Default setting: `path::String = "src/example"`


## Quick Start
```
julia> using GaussianBP
julia> Xbp, system = bp("data33_14.h5"; max = 100)
julia> Xbp, system = bp("data33_14.h5"; max = 100, damp = 10, bump = 50)
julia> Xbp, system = bp("data33_14.h5"; max = 100, damp = 10, bump = 50, algorithm = "kahan")
```

## More information:
- M. Cosovic and D. Vukobratovic, "Distributed Gauss-Newton Method for State Estimation Using Belief Propagation," in IEEE Transactions on  Power Systems, vol. 34, no. 1, pp. 648-658, Jan. 2019. [arxiv.org](https://arxiv.org/pdf/1702.05781.pdf)
- M. Cosovic, "Design and Analysis of Distributed State Estimation Algorithms Based on Belief Propagation and Applications in Smart Grids." arXiv preprint arXiv:1811.08355 (2018). [arxiv.org](https://arxiv.org/pdf/1811.08355.pdf)
