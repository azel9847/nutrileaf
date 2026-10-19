"""NutriLeaf — Nutrient Deficiency Recommendation Catalog.

Provides chemical (commercial) and traditional/organic recommendations for
each deficiency label detected by the Stage-2 MobileViT expert model, along
with credible source citations suitable for academic and thesis use.

Public API
----------
    from recommendations import get_recommendations

    recs = get_recommendations("nitrogen")
    # recs["chemical"]  -> {"practices": [...], "sources": [...]}
    # recs["organic"]   -> {"practices": [...], "sources": [...]}
"""
from __future__ import annotations

from typing import TypedDict


# ---------------------------------------------------------------------------
# Type definitions
# ---------------------------------------------------------------------------

class RecommendationCategory(TypedDict):
    """One recommendation category (chemical or organic)."""
    practices: list[str]
    sources: list[str]


class DeficiencyRecommendation(TypedDict):
    """Full recommendation block for a single deficiency label."""
    deficiency: str
    description: str
    chemical: RecommendationCategory
    organic: RecommendationCategory


# ---------------------------------------------------------------------------
# Catalog
# ---------------------------------------------------------------------------

_CATALOG: dict[str, DeficiencyRecommendation] = {

    # -- Healthy --------------------------------------------------------------
    "healthy": {
        "deficiency": "Healthy",
        "description": (
            "No nutrient deficiency detected. The plant displays normal leaf "
            "color and vigour. Maintain current soil fertility and cultural "
            "management practices."
        ),
        "chemical": {
            "practices": [
                "Continue balanced fertilization schedule: apply a complete NPK "
                "fertilizer (e.g., 14-14-14) at the recommended maintenance rate "
                "of 1-2 bags (50 kg) per hectare per cropping season.",
                "Monitor soil pH every cropping cycle; maintain pH 6.0-7.0 for "
                "optimal macronutrient availability. Apply agricultural lime "
                "(dolomite) if pH falls below 5.5.",
                "Conduct periodic soil testing (every 2-3 seasons) to pre-empt "
                "latent nutrient imbalances before visual symptoms appear.",
            ],
            "sources": [
                "Bureau of Plant Industry (BPI), Department of Agriculture — "
                "Crop Production Guide for Vegetables in the Philippines (2019).",
                "Fertilizer and Pesticide Authority (FPA) — Recommended Fertilizer "
                "Rates for Vegetable Crops, DA Circular No. 01-2018.",
                "Landon, J.R. (Ed.) (1991). Booker Tropical Soil Manual. "
                "Longman Scientific & Technical, UK.",
            ],
        },
        "organic": {
            "practices": [
                "Apply well-aged compost at 5-10 t/ha before land preparation to "
                "sustain soil organic matter and microbial activity.",
                "Incorporate green manure crops (e.g., mungbean, cowpea) between "
                "cropping seasons to add nitrogen and improve soil structure.",
                "Use mulching with rice straw or dried leaves to conserve soil "
                "moisture and suppress weeds, reducing nutrient leaching.",
                "Inoculate seedlings with mycorrhizal biofertilizers to enhance "
                "phosphorus uptake efficiency without additional chemical inputs.",
            ],
            "sources": [
                "Philippine Center for Postharvest Development and Mechanization "
                "(PhilMech) — Organic Farming Practices for Vegetable Producers (2020).",
                "University of the Philippines Los Banos (UPLB) — Institute of Plant "
                "Breeding, Integrated Crop Management Handbook, 4th ed. (2018).",
                "Reganold, J.P. & Wachter, J.M. (2016). Organic agriculture in the "
                "twenty-first century. Nature Plants, 2, 15221. "
                "https://doi.org/10.1038/nplants.2015.221",
            ],
        },
    },

    # -- Nitrogen -------------------------------------------------------------
    "nitrogen": {
        "deficiency": "Nitrogen",
        "description": (
            "Nitrogen (N) deficiency causes uniform yellowing (chlorosis) of older "
            "leaves first, stunted growth, and pale-green overall appearance. "
            "Nitrogen is the primary driver of vegetative growth and chlorophyll "
            "synthesis."
        ),
        "chemical": {
            "practices": [
                "Apply urea (46-0-0) at 45-60 kg N/ha split into two applications: "
                "one-half at transplanting (basal) and one-half at 3-4 weeks after "
                "transplanting (side-dress), following DA-BPI rates for leafy and "
                "fruiting vegetables.",
                "Alternatively, use ammonium sulfate (21-0-0) at 100-130 kg/ha; "
                "preferred on alkaline soils as it slightly acidifies the rhizosphere.",
                "For rapid correction in severe cases, apply foliar urea solution "
                "(1-2% w/v, approximately 10-20 g urea per liter of water) every "
                "7-10 days until green color returns. Spray early morning or late "
                "afternoon to prevent leaf burn.",
                "Use slow-release nitrogen sources (e.g., polymer-coated urea) in "
                "sandy or high-rainfall areas to minimize leaching losses.",
            ],
            "sources": [
                "Bureau of Plant Industry (BPI), Department of Agriculture — "
                "Fertilizer Recommendation for Vegetable Crops, BPI Technical "
                "Bulletin No. 211 (2021).",
                "Fertilizer Industry Association of the Philippines (FIAP) — "
                "Guide to Nitrogen Fertilization of Field Vegetables (2019).",
                "Marschner, P. (Ed.) (2012). Marschner's Mineral Nutrition of "
                "Higher Plants, 3rd ed. Academic Press, London. "
                "ISBN 978-0-12-384905-2.",
                "Cakmak, I. & Yazici, A.M. (2010). Magnesium: A forgotten element "
                "in crop production. Better Crops, 94(2), 23-25.",
            ],
        },
        "organic": {
            "practices": [
                "Apply well-aged poultry manure (chicken dung) at 3-5 t/ha; "
                "poultry manure provides approximately 1.6-3.5% N and improves "
                "soil microbial populations. Incorporate 2 weeks before planting.",
                "Use fermented plant juice (FPJ) made from young leafy plant "
                "material (e.g., kangkong, madre de agua) diluted at 1:500 v/v "
                "as a weekly foliar spray to supply readily absorbed organic "
                "nitrogen and growth-promoting hormones.",
                "Incorporate indigenous microorganism (IMO) cultures with rice "
                "bran and molasses into the topsoil to stimulate nitrogen "
                "mineralization from organic matter; apply 2 weeks before "
                "transplanting.",
                "Plant nitrogen-fixing cover crops (e.g., Leucaena, Sesbania, "
                "or cowpea) and incorporate as green manure 2-3 weeks before "
                "main crop planting; green manure can supply 40-80 kg N/ha.",
                "Apply compost tea (extracted from finished compost at 1:10 "
                "compost-to-water ratio) as a soil drench every 2 weeks to "
                "deliver soluble organic nitrogen and beneficial microbes.",
            ],
            "sources": [
                "Department of Agriculture — Bureau of Soils and Water Management "
                "(BSWM), Organic Fertilizer Production and Use Manual (2017).",
                "Cho, J.Y. (2010). Natural Farming: Agriculture Materials. "
                "ECHO Asia Impact Center, Chiang Mai, Thailand.",
                "Philippine Rice Research Institute (PhilRice) — Organic Rice "
                "Farming Manual: IMO and FPJ Preparation, 2nd ed. (2016).",
                "Peoples, M.B. & Craswell, E.T. (1992). Biological nitrogen "
                "fixation: Investments, expectations and actual contributions to "
                "agriculture. Plant and Soil, 141(1), 13-39. "
                "https://doi.org/10.1007/BF00011308",
            ],
        },
    },

    # -- Phosphorus -----------------------------------------------------------
    "phosphorus": {
        "deficiency": "Phosphorus",
        "description": (
            "Phosphorus (P) deficiency produces dark-green or purplish-red "
            "discoloration on older leaves and stems (due to anthocyanin "
            "accumulation), delayed maturity, and poor root development. "
            "Phosphorus is critical for energy transfer (ATP), root establishment, "
            "and fruit set."
        ),
        "chemical": {
            "practices": [
                "Apply single superphosphate (0-20-0) at 60-90 kg P2O5/ha banded "
                "5-10 cm below and beside the seed row or transplant hole for "
                "maximum root interception.",
                "Alternatively, use triple superphosphate (0-46-0) at 25-35 kg/ha "
                "to supply equivalent phosphorus with lower bulk; suited for "
                "small-holder plots with limited carrying capacity.",
                "On acid soils (pH < 5.5), apply agricultural lime at 1-2 t/ha "
                "at least 2 weeks before phosphate fertilization to raise pH and "
                "reduce phosphorus fixation by iron and aluminum oxides.",
                "For established crops showing deficiency symptoms, apply a "
                "phosphate-containing water-soluble foliar fertilizer such as "
                "mono-potassium phosphate (0-52-34) at 3-5 g/L every 10 days "
                "as a corrective foliar feed.",
            ],
            "sources": [
                "Bureau of Plant Industry (BPI), Department of Agriculture — "
                "Phosphorus Fertilization Guidelines for Vegetable Production "
                "(BPI Advisory No. 18-2020).",
                "International Fertilizer Development Center (IFDC) — A Manual "
                "for the Evaluation of Fertilizers, 3rd ed. (2016).",
                "Brady, N.C. & Weil, R.R. (2010). Elements of the Nature and "
                "Properties of Soils, 3rd ed. Pearson Education, New Jersey. "
                "ISBN 978-0-13-501433-2.",
                "Shenoy, V.V. & Kalagudi, G.M. (2005). Enhancing plant phosphorus "
                "use efficiency for sustainable cropping. Biotechnology Advances, "
                "23(7-8), 501-513. https://doi.org/10.1016/j.biotechadv.2005.01.004",
            ],
        },
        "organic": {
            "practices": [
                "Apply natural ground rock phosphate at 300-500 kg/ha incorporated "
                "into the soil before planting; best suited for acidic soils "
                "(pH 5.0-6.0) where citric acid solubilization is greatest.",
                "Use bone meal or fish bone meal (3-6% P2O5) at 1-2 t/ha mixed "
                "into the topsoil 2-3 weeks before planting as a slow-release "
                "phosphorus source.",
                "Inoculate seeds or transplant roots with phosphate-solubilizing "
                "bacteria (PSB) biofertilizer (e.g., Bacillus megaterium, "
                "Pseudomonas fluorescens) available from BSWM or PhilRice to "
                "mobilize native and applied phosphorus.",
                "Prepare fermented fruit juice (FFJ) from ripe banana (high in "
                "phosphorus and potassium) by mixing 1 kg chopped fruit with "
                "1 kg brown sugar, fermenting for 7 days, then diluting 1:500 "
                "v/v as a foliar spray every 10-14 days.",
                "Apply banana peel liquid fertilizer: soak dried banana peels in "
                "water (1:10 w/v) for 48 hours, strain, and apply as a root "
                "drench weekly; rich in phosphorus and potassium.",
            ],
            "sources": [
                "Bureau of Soils and Water Management (BSWM), Department of "
                "Agriculture — Biofertilizer: Phosphate-Solubilizing Bacteria "
                "Production Guide (2018).",
                "Vessey, J.K. (2003). Plant growth promoting rhizobacteria as "
                "biofertilizers. Plant and Soil, 255(2), 571-586. "
                "https://doi.org/10.1023/A:1026037216893",
                "Cho, J.Y. (2010). Natural Farming: Agriculture Materials. "
                "ECHO Asia Impact Center, Chiang Mai, Thailand.",
                "UPLB Institute of Plant Breeding — Organic and Natural Farming "
                "Resource Kit for Vegetable Growers (2019).",
            ],
        },
    },

    # -- Potassium ------------------------------------------------------------
    "potassium": {
        "deficiency": "Potassium",
        "description": (
            "Potassium (K) deficiency manifests as marginal leaf scorch (brown, "
            "crispy leaf edges), interveinal chlorosis on older leaves, and weak "
            "stems. Potassium regulates stomatal function, water-use efficiency, "
            "enzyme activation, and overall stress tolerance."
        ),
        "chemical": {
            "practices": [
                "Apply muriate of potash (MOP / KCl, 0-0-60) at 60-80 kg K2O/ha "
                "split equally at planting and 4 weeks after transplanting. "
                "Broadcast and incorporate or band-apply beside the plant row.",
                "On chloride-sensitive crops or high-value production, substitute "
                "MOP with sulfate of potash (SOP / K2SO4, 0-0-50) at "
                "120-160 kg/ha; SOP also supplies sulfur (18% S) beneficial for "
                "protein synthesis.",
                "For corrective foliar application, spray potassium nitrate "
                "(13-0-46) at 5-10 g/L every 7-10 days until marginal scorch "
                "stops progressing; potassium nitrate also supplies supplemental "
                "nitrogen.",
                "Ensure balanced NPK ratios: potassium deficiency is often "
                "exacerbated by luxury nitrogen uptake; avoid over-application "
                "of nitrogenous fertilizers when K symptoms appear.",
            ],
            "sources": [
                "Bureau of Plant Industry (BPI), Department of Agriculture — "
                "Potassium Fertilization in Vegetable Crop Production "
                "(BPI Technical Note No. 5, 2022).",
                "International Potash Institute (IPI) — Potassium in Agriculture, "
                "Bulletin No. 8 (2003). Horgen, Switzerland.",
                "Romheld, V. & Kirkby, E.A. (2010). Research on potassium in "
                "agriculture: Needs and prospects. Plant and Soil, 335(1-2), "
                "155-180. https://doi.org/10.1007/s11104-010-0520-1",
                "Fertilizer and Pesticide Authority (FPA) — Fertilizer "
                "Recommendation Handbook for Vegetables in the Philippines "
                "(2020 Edition).",
            ],
        },
        "organic": {
            "practices": [
                "Apply wood ash (charcoal ash from rice hull or firewood) at "
                "500 kg to 1 t/ha incorporated into the topsoil before planting; "
                "wood ash contains 4-10% K2O and also supplies calcium and "
                "raises soil pH beneficially.",
                "Use banana stem and peel compost: chop banana pseudostem and "
                "peels, compost for 6-8 weeks with rice straw and animal manure, "
                "then apply at 3-5 t/ha before planting. Banana materials are "
                "among the richest organic potassium sources (1.5-3% K).",
                "Prepare water-extracted banana peel fertilizer: soak 1 kg dried "
                "banana peels in 10 L water for 24-48 hours, filter, and apply "
                "as a weekly root drench or diluted foliar spray (1:3 v/v).",
                "Apply seaweed extract (e.g., from Sargassum, Caulerpa) at "
                "3-5 mL/L as a foliar spray; seaweeds provide readily absorbed "
                "potassium, alginic acid, and natural plant growth regulators.",
                "Incorporate aged cattle or carabao manure at 5-10 t/ha; "
                "well-composted ruminant manure supplies 0.4-0.6% K plus "
                "improves soil water-holding capacity.",
            ],
            "sources": [
                "Department of Agriculture — Bureau of Soils and Water Management "
                "(BSWM), Wood Ash and Organic Materials as Soil Amendments "
                "Technical Bulletin (2017).",
                "Organic Agriculture Act of the Philippines, Republic Act No. 10068 "
                "— Implementing Rules and Regulations, Annex A: Approved Organic "
                "Inputs (2010).",
                "Cho, J.Y. (2010). Natural Farming: Agriculture Materials. "
                "ECHO Asia Impact Center, Chiang Mai, Thailand.",
                "Khan, S.A., Mulvaney, R.L. & Ellsworth, T.R. (2014). The potassium "
                "paradox: Implications for soil fertility, crop production and "
                "human health. Renewable Agriculture and Food Systems, 29(1), "
                "3-27. https://doi.org/10.1017/S1742170513000318",
                "PhilRice — Organic Fertilizer Sources and Their Nutrient Content "
                "Reference Guide, 3rd ed. (2021). Philippine Rice Research "
                "Institute, Nueva Ecija.",
            ],
        },
    },
}


# ---------------------------------------------------------------------------
# Public API
# ---------------------------------------------------------------------------

def get_recommendations(deficiency: str) -> DeficiencyRecommendation:
    """Return the recommendation block for *deficiency*.

    Parameters
    ----------
    deficiency:
        One of ``"healthy"``, ``"nitrogen"``, ``"phosphorus"``,
        ``"potassium"`` (case-insensitive).

    Returns
    -------
    DeficiencyRecommendation
        Dict containing ``deficiency``, ``description``, ``chemical``,
        and ``organic`` keys, each with ``practices`` and ``sources`` lists.

    Raises
    ------
    KeyError
        If *deficiency* is not found in the catalog.
    """
    key = deficiency.lower().strip()
    if key not in _CATALOG:
        raise KeyError(
            f"No recommendation found for deficiency label '{deficiency}'. "
            f"Available labels: {sorted(_CATALOG.keys())}"
        )
    return _CATALOG[key]
