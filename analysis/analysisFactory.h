#include <analysis.h>

namespace analysis
{

/*! \brief Used to create passes by name */
class AnalysisFactory
{
public:
	typedef Analysis::StringVector StringVector;

public:
	/*! \brief Create a analysis object from the specified name */
	static Analysis* createAnalysis(const std::string& name,
		const StringVector& options = StringVector());

};

}


