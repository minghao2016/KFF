#include <controlDependenceAnalysis.h>
#include <postdominatorTree.h>
#include <cassert>

// Preprocessor Macros
#ifdef REPORT_BASE
#undef REPORT_BASE
#endif

#define REPORT_BASE 0

namespace analysis
{

ControlDependenceAnalysis::ControlDependenceAnalysis()
: KernelAnalysis("ControlDependenceAnalysis", {"PostDominatorTreeAnalysis"})
{

}

typedef ir::ControlFlowGraph::iterator block_iterator;
typedef ir::PTXInstruction PTXInstruction;
typedef std::vector<block_iterator> BlockVector;

static PTXInstruction* getBranch(block_iterator block);

static BlockVector getControlDependentBlocks(block_iterator block,
	PostdominatorTree* pdom);

void ControlDependenceAnalysis::analyze(ir::IRKernel& kernel)
{
	// Create nodes
	for(auto block = kernel.cfg()->begin();
		block != kernel.cfg()->end(); ++block)
	{
		for(auto instruction : block->instructions)
		{
			auto ptx = static_cast<PTXInstruction*>(instruction);
			
			auto node = _nodes.insert(_nodes.end(), Node(ptx));
		
			_instructionToNodes.insert(std::make_pair(ptx, node));
		}
	}
	
	report("Running control dependence analysis on kernel " << kernel.name);
	
	auto pdom = static_cast<PostdominatorTree*>(
		getAnalysis("PostDominatorTreeAnalysis"));
	
	// Add dependencies from branches to all instructions in control
	//  dependent blocks
	for(auto block = kernel.cfg()->begin();
		block != kernel.cfg()->end(); ++block)
	{
		auto branch = getBranch(block);
		
		if(branch == nullptr) continue;
		
		auto dependentBlocks = getControlDependentBlocks(block, pdom);

		auto branchNode = getNode(branch);
		assert(branchNode != end());
		
		for(auto dependentBlock : dependentBlocks)
		{
			for(auto instruction : dependentBlock->instructions)
			{
				auto ptx = static_cast<PTXInstruction*>(instruction);
			
				auto instructionNode = getNode(ptx);
				assert(instructionNode != end());
				
				branchNode->successors.push_back(instructionNode);
				instructionNode->predecessors.push_back(branchNode);
				
				report(" " << branchNode->instruction->toString() << " -> "
					<< instructionNode->instruction->toString());
			}
		}
	}
}

static PTXInstruction* getBranch(block_iterator block)
{
	if(block->instructions.empty()) return nullptr;
	
	auto ptx = static_cast<PTXInstruction*>(block->instructions.back());
	
	if(ptx->isBranch()) return ptx;
	
	return nullptr;
}

static BlockVector getControlDependentBlocks(block_iterator block,
	PostdominatorTree* pdom)
{
	return pdom->getPostDominanceFrontier(block);
}

}


