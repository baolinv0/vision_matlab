
#ifndef OPENCV_MWFLANN_DUMMY_H_
#define OPENCV_MWFLANN_DUMMY_H_

namespace cvmwflann
{

#if (defined WIN32 || defined _WIN32 || defined WINCE) && defined CVAPI_EXPORTS
__declspec(dllexport)
#endif
void dummyfunc();

}


#endif  /* OPENCV_MWFLANN_DUMMY_H_ */
