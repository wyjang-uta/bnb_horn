#include "ROOT/RDataFrame.hxx"
#include "TCanvas.h"
#include "TFile.h"
#include "TH1D.h"
#include "TH2D.h"

void bnb_plot(std::string inputFile="input.root", std::string outputFile="output.root"){
    TFile* f = TFile::Open(inputFile.c_str());
    if (!f || f->IsZombie()) return;
    TString treeName = f->GetListOfKeys()->At(0)->GetName();
    ROOT::RDataFrame df(treeName, inputFile);

    auto df_valid = df.Filter("daughterE > 0");

    auto df_numu = df_valid.Filter("daughterPDG == 14 && daughterPz > 0");
    auto df_numubar = df_valid.Filter("daughterPDG == -14 && daughterPz > 0");
    auto df_nue = df_valid.Filter("daughterPDG == 12 && daughterPz > 0");
    auto df_nuebar = df_valid.Filter("daughterPDG == -12 && daughterPz > 0");

    /*
    auto df_numu_activeVol = df_valid.Filter("daughterPDG=14 && daughterPz > 0 && x_at_110m > -1.26 && x_at_110m < 2.74 && y_at_110m > -2.00 && y_at_110m < 2.00");
    auto df_numubar_activeVol = df_valid.Filter("daughterPDG=-14 && daughterPz > 0 && x_at_110m > -1.26 && x_at_110m < 2.74 && y_at_110m > -2.00 && y_at_110m < 2.00");
    auto df_numu_activeVol = df_valid.Filter("daughterPDG=12 && daughterPz > 0 && x_at_110m > -1.26 && x_at_110m < 2.74 && y_at_110m > -2.00 && y_at_110m < 2.00");
    auto df_numubar_activeVol = df_valid.Filter("daughterPDG=-12 && daughterPz > 0 && x_at_110m > -1.26 && x_at_110m < 2.74 && y_at_110m > -2.00 && y_at_110m < 2.00");
    */

    auto h_energy = df_valid.Histo1D(
        {"h_energy", "Neutrino Energy; Energy (GeV);Counts", 100, 0, 5},
        "daughterE"
    );

    auto h_profile = df_valid.Histo2D(
        {"h_profile", "Neutrino Profile at SBND(110 m); x []; y [m]", 100, -5, 5, 100, -5, 5},
        "x_sbnd", "y_at_110m"
    );

    auto df_numu_ff = df_numu.Filter("x_at_110m > -1.26 && x_at_110m < 2.74 && y_at_110m > -2.00 && y_at_110m < 2.00");
    auto df_numubar_ff = df_numubar.Filter("x_at_110m > -1.26 && x_at_110m < 2.74 && y_at_110m > -2.00 && y_at_110m < 2.00");
    auto df_nue_ff = df_nue.Filter("x_at_110m > -1.26 && x_at_110m < 2.74 && y_at_110m > -2.00 && y_at_110m < 2.00");
    auto df_nuebar_ff = df_nuebar.Filter("x_at_110m > -1.26 && x_at_110m < 2.74 && y_at_110m > -2.00 && y_at_110m < 2.00");

    auto h_numu_ff_daughterE = df_numu_ff.Histo1D({"h_numu_ff_daughterE", "Numu daughterE after FF; daughterE; Events", 200, 0, 20},"daughterE");
    auto h_numubar_ff_daughterE = df_numubar_ff.Histo1D({"h_numubar_ff_daughterE", "Numubar daughterE after FF; daughterE; Events", 200, 0, 20},"daughterE");
    auto h_nue_ff_daughterE = df_nue_ff.Histo1D({"h_nue_ff_daughterE", "Nue daughterE after FF; daughterE; Events", 200, 0, 20},"daughterE");
    auto h_nuebar_ff_daughterE = df_nuebar_ff.Histo1D({"h_nuebar_ff_daughterE", "Nuebar daughterE after FF; daughterE; Events", 200, 0, 20},"daughterE");

    TFile out(outputFile.c_str(), "RECREATE");
    h_energy->Write();
    h_profile->Write();

    h_numu_ff_daughterE->Write();
    h_numubar_ff_daughterE->Write();
    h_nue_ff_daughterE->Write();
    h_nuebar_ff_daughterE->Write();

    out.Close();

    std::cout << ">>> Analysis complete: " << outputFile << std::endl;
}
