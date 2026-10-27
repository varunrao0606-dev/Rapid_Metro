# Public Transport or Corporate Shuttle? The Gurugram Rapid Metro

Data and code for:

Rao, V. (2026). *Public Transport or Corporate Shuttle? Analysing the Spatial-Economic Outcomes of the Gurugram Rapid Metro.* Manuscript submitted to *Transportation Research Part A: Policy and Practice*.

The paper estimates the effect of the two phases of the Gurugram Rapid Metro on ward-level economic activity, using satellite night-time lights (NTL) as a proxy. It uses a staggered difference-in-differences design across all 35 municipal wards of Gurugram from 2012 to 2023. Phase 1 (Cyber City, wards 34 and 35) opened in 2013 and Phase 2 (Golf Course Road, wards 32 and 33) in 2017.

The paper began as an MSc Economic Policy dissertation at SOAS University of London (2026).


## Repository contents

| File | Description |
|---|---|
| `GEE_Script` | Google Earth Engine script that extracts the night-time lights panel for each ward |
| `GGN_NTL.xlsx` | Ward-year panel (35 wards x 12 years = 420 observations) |
| `Stationwise Ridership.xlsx` | Station-level Rapid Metro ridership from DMRC (Table 3 of the paper) |
| `wards_gurugram.geojson` | Gurugram municipal ward boundaries. The ward ID used in the panel is `sourcewardcode` |
| `GMRL_alignment_approx.geojson` | Approximate route of the planned GMRL extension (see below) |
| `GGN_Rapid_Metro_Spatial.ipynb` | Colab notebook: ward areas, OSM metro lines and stations, 800 m station catchments, and the ward lists used in the Stata checks |
| `Gurugram_Rapid_Metro_Analysis.do` | All econometric results, tables and figures in the paper |
| `ward_lists_check.png` | Map of the treated, GMRL-route and neighbouring wards |
| `output/` | Tables (.rtf), figures (.pdf) and simulation draws (.dta) produced by the do-file |


## Data

### Panel variables (`GGN_NTL`)

| Variable | Description |
|---|---|
| `ward` | Ward number (1-35), matching `sourcewardcode` in the ward boundaries |
| `zone` | Municipal zone |
| `year` | 2012-2023 |
| `ln_ntl_radiance` | Annual night-time radiance for the ward, from `GEE_Script`. Despite its name it is in levels, and the do-file takes its log as `true_ln_ntl` |
| `phase1`, `phase2` | Treatment indicators (rebuilt in the do-file) |
| `hh`, `pop`, `area` | Households, population and ward area |
| `popdn` | Population density (baseline) |
| `blr` | Literacy rate (baseline) |
| `bsws` | Service-sector share of the workforce (baseline) |

### Sources

- **Night-time lights:** VIIRS DNB VCMCFG monthly composites (Elvidge et al., 2017), accessed through Google Earth Engine (`NOAA/VIIRS/DNB/MONTHLY_V1/VCMCFG`, band `avg_rad`). `GEE_Script` takes the median of the monthly composites for each year and records its value at each ward's centroid. The stray-light corrected VCMSLCFG series is not used because it starts only in 2014.
- **Baseline covariates:** Census of India 2011, District Census Handbook: Gurgaon (Directorate of Census Operations, Haryana, 2014). They are fixed at baseline and enter every model interacted with year.
- **Ward boundaries:** Gurugram municipal ward map (GeoJSON).
- **Metro lines and stations:** OpenStreetMap, through `osmnx`.

Station-level ridership data were provided by DMRC during fieldwork and are in `Stationwise Ridership.xlsx`.


## How to run

### 1. Night-time lights (Google Earth Engine)

Run `GEE_Script` in the Earth Engine Code Editor after uploading the ward boundaries as an asset. It exports a CSV of ward-year radiance, which forms the NTL column of `GGN_NTL.xlsx`.

### 2. Spatial preparation (Python)

Open `GGN_Rapid_Metro_Spatial.ipynb` in Google Colab (badge at the top of the notebook) and run `!pip install osmnx` first. Upload `wards_gurugram.geojson` and `GMRL_alignment_approx.geojson` to the Colab session and run the notebook. It prints ward areas, saves the OSM metro layers and 800 m catchments, and writes `Ward_Lists.csv`.

### 3. Econometric analysis (Stata)

Requires Stata. The do-file installs the user-written packages it needs: `reghdfe`, `ftools`, `csdid`, `drdid`, `coefplot` and `estout`. The wild cluster bootstrap is written into the do-file, so `boottest` is not needed.

Change the `cd` path at the top of `Gurugram_Rapid_Metro_Analysis.do` to your own folder and run the whole file. The bootstrap (999 draws for each phase) and the randomisation inference (465 pairs for each phase) take a few minutes.


## Where each result comes from

| Paper | Do-file section | Output |
|---|---|---|
| Table 4 | Baseline Model | `Table4_Baseline.rtf` |
| Table 5 | Robustness Checks | `Table5_Robustness.rtf` |
| Table 6 | Identification and Inference Checks | `Table6_Identification.rtf` |
| Table B.1 | Identification checks, f | `TableB1_ByWard.rtf` |
| Fig. 1 | Descriptive trends by ward cohort | `Figure_1.pdf` |
| Fig. 2 | Event Study (Callaway-Sant'Anna) | `Figure_2.pdf` |
| Fig. 3 | Sensitivity forest plot | `Figure_3.pdf` |
| Fig. B.1 | Identification checks, b | `Figure_B1a_RI_Phase1.pdf`, `Figure_B1b_RI_Phase2.pdf`, `RI_draws.dta` |
| Fig. B.2 | Identification checks, g | `Figure_B2_Jackknife.pdf`, `Jackknife.dta` |

Figs. 4 and 6 are fieldwork photographs and Fig. 5 is a QGIS map. They are not produced by the code.


## Identification and inference checks

Section 4.5 of the paper sets out five threats to identification. The do-file addresses them as follows.

- **Few treated wards.** Each phase has only two treated wards, so the do-file also reports restricted wild cluster bootstrap p-values with Webb weights and randomisation inference p-values. The randomisation inference gives each phase in turn to every possible pair of the 31 never-treated wards (31 x 30 / 2 = 465 pairs). It then compares the true estimate with that placebo distribution.
- **Non-random placement.** Controls are restricted to the wards along the planned GMRL route. These wards were also chosen for a metro but do not have one yet.
- **Spillovers.** The untreated wards bordering the treated corridors are dropped.
- **Anticipation.** Phase 2 is dated from its October 2012 concession award instead of its 2017 opening.
- **Single-ward influence.** Ward-by-ward estimates and a jackknife that drops one ward at a time.


## Ward lists and the planned GMRL route

No official shapefile of the planned Gurugram Metro Rail Limited (GMRL) extension is publicly available. Its route was therefore approximated, with AI assistance, from published station locations and drawn in QGIS (Fig. 5 in the paper). `GMRL_alignment_approx.geojson` is that line traced back onto the ward map. It is an approximation and should not be read as the official alignment.

- **GMRL-route wards:** untreated wards with at least a quarter of their area within 800 m of the route. Ward 29 also qualifies but is left out, as it is the Yellow Line control ward.
- **Neighbouring wards:** untreated wards sharing a boundary with wards 32-35.

The lists used in the paper are:

```
GMRL_WARDS  2 3 4 5 6 10 11 12 14 19 20 21 27 28 30
NEIGHBOURS  4 17 25 29 30 31
```

Ward 28 sits close to the 25% cut-off. Small differences in how the route is traced move it either side of the line. It was just above the cut-off in the version used for the paper. The line in this repository puts it at about 21%, so the notebook returns 14 wards without it. The do-file keeps the 15-ward list behind Table 6 and also reports the GMRL-route estimate without ward 28.


## Use of AI tools

Claude (Anthropic) was used to help generate parts of the Stata and Python code and to approximate the planned GMRL route. All code was reviewed and run by the author, who takes full responsibility for it.


## Citation

If you use this data or code, please cite the paper above (citation details will be updated on publication).


## Licence

Code: MIT License. Data: CC BY 4.0.


## Contact

Varun Rao, UCLouvain, Belgium. varunrao0606@gmail.com
