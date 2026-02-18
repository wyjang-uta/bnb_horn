#include <ROOT/RDataFrame.hxx>

void project_at_110m(const char* ifname="filename.root", const char* ofname="ofname.root") {
  ROOT::RDataFrame df("bnb", ifname);
  double targetZ = 110.0; // unit in m

  auto df_extrapolated = df.Define("x_at_110m", 
        [targetZ](double x, double z, double px, double pz) {
            if (pz == 0) return -9999.9; // 분모가 0인 경우 예외 처리
            return x + (targetZ - z) * (px / pz);
        }, {"vertexX", "vertexZ", "daughterPx", "daughterPz"})
    .Define("y_at_110m", 
        [targetZ](double y, double z, double py, double pz) {
            if (pz == 0) return -9999.9;
            return y + (targetZ - z) * (py / pz);
        }, {"vertexY", "vertexZ", "daughterPy", "daughterPz"})
    .Define("x_sbnd",
        [](double x) {
        return x + 0.74;
        }, {"x_at_110m"});
    df_extrapolated.Snapshot("bnb_new", ofname);
}
