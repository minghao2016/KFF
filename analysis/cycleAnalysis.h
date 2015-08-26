#include <analysis.h>
#include <list>
#include <unordered_set>

namespace analysis
{

/*! \brief Analysis that detects cycles in the control flow graph. */
class CycleAnalysis: public KernelAnalysis
{
public:
	typedef ir::ControlFlowGraph CFG;
	
	typedef CFG::const_iterator const_iterator;
	typedef CFG::iterator       iterator;
	
	typedef CFG::const_edge_iterator const_edge_iterator;
	typedef CFG::edge_iterator       edge_iterator;
	
	typedef std::list<edge_iterator> EdgeList;

public:
	/*! \brief Create the analysis */
	CycleAnalysis();

	/*! \brief Computes an up to date set of cycles */
	void analyze(ir::IRKernel& kernel);

public:
	/*! \brief Get the list of all back edges in the CFG */
	EdgeList getAllBackEdges() const;

	/*! \brief Test if a specific edges is a back edge */
	bool isBackEdge(edge_iterator edge) const;
	
private:
	typedef std::unordered_set<edge_iterator> EdgeSet;
	
private:
	EdgeSet _backEdges;
	
};

}

