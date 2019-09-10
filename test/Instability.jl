module Instability

using SparseArrays
using HDF5
using Test
using Random
using Printf


################################################################################
# Read data from SimpleTest.h5
#-------------------------------------------------------------------------------
function model(DATA, PATH)
    system = string(PATH, DATA, ".h5")

    Hlist = h5read(system, "/H")
    H = sparse(Hlist[:,1], Hlist[:,2], Hlist[:,3])

    b = h5read(system, "/b")
    v = h5read(system, "/v")

    return H, b, v
end

H, b, v = model("SimpleTest", "test/")
################################################################################


################################################################################
# Check for type stability function by function
#-------------------------------------------------------------------------------
include("../src/factorgraph.jl")
Nf, Nv, T = @inferred graph(H)
Nld, Nli, dir = @inferred links(Nf, T)
vir = @inferred virtuals(Nv, dir)                                                                                         # factorgraph.jl
Ii, Ji, Ni, bi, vi, Hi, md, vid = @inferred factors(Nf, Nv, Nld, Nli, T, b, v, vir, 0.0, 1e3)                           # factorgraph.jl

include("../src/auxiliary.jl")
m_fv, vi_fv, m_vf, v_vf = @inferred load_messages(Hi)
msr, vsr, msc, vsc = @inferred load_sum(Nv, Ni)
msr, vsr, msc, vsc = @inferred clear_sum(msr, vsr, msc, vsc)
msr, vsr, evr, msc, vsc, evc = @inferred nload_sum(Nv, Ni)
msr, vsr, evr, msc, vsc, evc = @inferred nclear_sum(msr, vsr, evr, msc, vsc, evc)                                             # AuxiliaryFunction

include("../src/initialize.jl")
ah1, ah2 = @inferred damping(Nli, 0.5, 0.5)                                                                                 # InitializeMessages
m_vf, v_vf = @inferred forward_directs(Hi, Ji, Nli, md, vid, v_vf, m_vf)

include("../src/summation.jl")
msr, vsr = @inferred sum_rows(Hi, Ii, Nli, m_vf, v_vf, msr, vsr)                                                          # summation.jl
msc, vsc = @inferred sum_cols(Ji, Nli, m_fv, vi_fv, msc, vsc)                                                         # summation.jl
msr, vsr, evr = @inferred nsum_rows(Hi, Ii, Nli, m_vf, v_vf, msr, vsr, evr)                                                   # SummationBelief
msc, vsc, evc = @inferred nsum_cols(Ji, Nli, m_fv, vi_fv, msc, vsc, evc)

include("../src/inference.jl")
m_fv, vi_fv = @inferred factor_to_variable(m_vf, v_vf, m_fv, vi_fv, msr, vsr, Hi, bi, vi, Ii, Nli)                        # inference.jl
m_vf, v_vf = @inferred variable_to_factor(m_vf, v_vf, m_fv, vi_fv, md, vid, msc, vsc, Ji, Nli)                        # inference.jl
m_fv, vi_fv = @inferred factor_to_variable(m_vf, v_vf, m_fv, vi_fv, msr, vsr, Hi, bi, vi, Ii, Nli)                # inference.jl
m_fv, vi_fv = @inferred dfactor_to_variable(m_vf, v_vf, m_fv, vi_fv, msr, vsr, Hi, bi, vi, Ii, Nli, ah1, ah2)     # inference.jl
xbp = @inferred marginal(md, vid, msc, vsc, Ji, Nv)                                                                       # inference.jl
m_fv, vi_fv = @inferred nfactor_to_variable(m_vf, v_vf, m_fv, vi_fv, msr, vsr, evr, Hi, bi, vi, Ii, Nli)                      # BeliefPropagation
m_vf, v_vf = @inferred nvariable_to_factor(m_vf, v_vf, m_fv, vi_fv, md, vid, msc, vsc, evc, Ji, Nli)                      # BeliefPropagation
m_fv, vi_fv = @inferred nfactor_to_variable(m_vf, v_vf, m_fv, vi_fv, msr, vsr, evr, Hi, bi, vi, Ii, Nli)              # BeliefPropagation
m_fv, vi_fv = @inferred ndfactor_to_variable(m_vf, v_vf, m_fv, vi_fv, msr, vsr, evr, Hi, bi, vi, Ii, Nli, ah1, ah2)   # BeliefPropagation
xbp = @inferred nmarginal(md, vid, msc, vsc, evc, Ji, Nv)
################################################################################


################################################################################
# Check for type stability of main functions
#-------------------------------------------------------------------------------
include("../src/evaluation.jl")
include("../src/simplybp.jl")
include("../src/neumaierbp.jl")
@inferred bps(H, b, v, 10, 5, 0.6, 0.5, 0.0, 1e-3, "on")
@inferred bpn(H, b, v, 10, 5, 0.6, 0.5, 0.0, 1e-3, "on")
################################################################################
end