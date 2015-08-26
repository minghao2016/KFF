#ifndef IR_DOMINATORTREE_H_INCLUDED
#define IR_DOMINATORTREE_H_INCLUDED

#include <analysis.h>
#include <vector>

namespace analysis {
	
/*!
	A tree structure in which each node corresponds to a BasicBlock in the
	control flow graph such that each node's block is immediately dominated
	by its parent. Each node is owned by its parent.
*/
class DominatorTree : public KernelAnalysis {
	
public:
	DominatorTree();
	~DominatorTree();

public:
	void analyze(ir::IRKernel& kernel);

public:		
	/*! Writes a representation of the DominatorTree to an output stream */
	std::ostream& write(std::ostream &out);

	/*! Parent control flow graph */
	ir::ControlFlowGraph *cfg;

	/*! the basic blocks in the CFG and dominator tree */
	ir::ControlFlowGraph::BlockPointerVector blocks;

	/*! nth element stores the immediate 
		dominator of node n or -1 if undefined */
	std::vector< int > i_dom;

	/*! nth element stores a list of elements for which 
		n is the immediate dominator */
	std::vector< std::vector<int> > dominated;

	/*! Mapping from a BasicBlock to an index into the blocks vector */
	ir::ControlFlowGraph::BlockMap blocksToIndex;

	/*! Does a particular block dominate another block? */
	bool dominates(ir::ControlFlowGraph::const_iterator block, 
		ir::ControlFlowGraph::const_iterator potentialSuccessor);

	/*! Get the dominator of a given block */
	ir::ControlFlowGraph::iterator getDominator(
		ir::ControlFlowGraph::const_iterator block);
		
	/*! Get the nearest common dominator of two blocks */
	ir::ControlFlowGraph::iterator getCommonDominator(
		ir::ControlFlowGraph::const_iterator block1,
		ir::ControlFlowGraph::const_iterator block2);
	
	/*! Get the set of blocks immediately dominated by the specified block */
	ir::ControlFlowGraph::BlockPointerVector getDominatedBlocks(
		ir::ControlFlowGraph::const_iterator block);
	
private:
	void computeDT();
	int intersect(int b1, int b2) const;
};
	
}

#endif

