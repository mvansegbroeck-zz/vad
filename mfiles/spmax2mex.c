/*

  spmax2.c	max over all non-zero cols of a matrix

   [y,arg]=spmax2(row,col,val1,val2,N)
is equivalent to [y,arg]=spmax(x)
where x has N cols and is given by val1+val2 in position(row,col). If val1==-INF => entry disregarded
-INF in y signify that column was empty.

*/

#include <math.h>
#include <float.h>
#include "mex.h"

#define row		prhs[0]
#define col		prhs[1]
#define val1		prhs[2]
#define val2		prhs[3]
#define NbCol		prhs[4]

#define y		plhs[0]
#define arg		plhs[1]

void mexFunction(
	int	nlhs,
	mxArray	*plhs[],
	int	nrhs,
	const mxArray	*prhs[]
	)

{
double		*py, *parg;
double		*prow, *pcol, *pval1, *pval2;
double		val;
int		N, NNZ, i;

/* Check for proper number of arguments */
if (nrhs != 5)
  mexErrMsgTxt("spmax2 requires five input argument2.");

N=*mxGetPr(NbCol);
NNZ=mxGetM(row)*mxGetN(row);

if (mxGetM(col)*mxGetN(col) != NNZ) mexErrMsgTxt("row, col, val1 and val2 must be isomorphic.");
if (mxGetM(val1)*mxGetN(val1) != NNZ) mexErrMsgTxt("row, col, val1 and val2 must be isomorphic.");
if (mxGetM(val2)*mxGetN(val2) != NNZ) mexErrMsgTxt("row, col, val1 and val2 must be isomorphic.");

y  =mxCreateDoubleMatrix(1,N,mxREAL);
py =mxGetPr(y);
for (i=0; i<N; i++) py[i]=-INFINITY;

arg=mxCreateDoubleMatrix(1,N,mxREAL);
parg=mxGetPr(arg);

prow =mxGetPr(row);
pcol =mxGetPr(col);
pval1=mxGetPr(val1);
pval2=mxGetPr(val2);

for (i=0; i<NNZ ; i++, prow++, pcol++, pval1++, pval2++) {
	if (*pval1 != -INFINITY) {
		val = *pval1 + *pval2;
		if (val > py[(int)(*pcol)-1]) {
			py[(int)(*pcol)-1]=val;
			parg[(int)(*pcol)-1]=*prow;
		}
	}
}

}

