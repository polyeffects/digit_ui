import QtQuick 2.4
import QtQuick.Window 2.2
import QtQuick.Controls 2.3
import QtQuick.Controls.Material 2.3

// ApplicationWindow {

//     Material.theme: Material.Dark
//     Material.primary: Material.Green
//     Material.accent: Material.Pink

//     readonly property int baseFontSize: 20 
//     readonly property int tabHeight: 60 
//     readonly property int fontSizeExtraSmall: baseFontSize * 0.8
//     readonly property int fontSizeMedium: baseFontSize * 1.5
//     readonly property int fontSizeLarge: baseFontSize * 2
//     readonly property int fontSizeExtraLarge: baseFontSize * 5
//     width: 800
//     height: 580
//     title: "Drag & drop example"
//     visible: true

    Item {
        id: time_scale
        width: 800
        height: 550
        property string effect: "eq2"
        property bool eq_enabled: polyValues[effect]["enable"].value
        property int active_width: 675
        property int selected_point: 1
        property int point_updated: 1
        property int updateCount: updateCounter, externalRefresh()

        // q is 0-4 gain is +-18 db
        property var eq_data: [{"frequency": polyValues[effect]["LSfreq"].value, 
            "gain": polyValues[effect]["LSgain"].value, "q": polyValues[effect]["LSq"].value,
            "enabled":polyValues[effect]["LSsec"].value},
            {"frequency": polyValues[effect]["freq1"].value, "gain": polyValues[effect]["gain1"].value, 
            "q": polyValues[effect]["q1"].value, "enabled":polyValues[effect]["sec1"].value},
            {"frequency": polyValues[effect]["freq2"].value, "gain": polyValues[effect]["gain2"].value, 
            "q": polyValues[effect]["q2"].value, "enabled":polyValues[effect]["sec2"].value},
            {"frequency": polyValues[effect]["freq3"].value, "gain": polyValues[effect]["gain3"].value,
            "q": polyValues[effect]["q3"].value, "enabled":polyValues[effect]["sec3"].value},
            {"frequency": polyValues[effect]["freq4"].value, "gain": polyValues[effect]["gain4"].value,
            "q": polyValues[effect]["q4"].value, "enabled":polyValues[effect]["sec4"].value},
            {"frequency": polyValues[effect]["HSfreq"].value, "gain": polyValues[effect]["HSgain"].value,
            "q": polyValues[effect]["HSq"].value, "enabled":polyValues[effect]["HSsec"].value}]
        

        function hzToPixel(f) {
            return mycanvas.x_at_freq (f, active_width);
        }

        function pixelToHz(x) {
            return mycanvas.freq_at_x (x, active_width);
        }

        function externalRefresh() {
            // console.log("external refresh");
            for (var i = 0; i < time_scale.eq_data.length; i++) {
                mycanvas.update_filter_external (i, 
                    time_scale.eq_data[i]["frequency"], 
                    time_scale.eq_data[i]["q"], 
                    time_scale.eq_data[i]["gain"]);
            }
            mycanvas.requestPaint();
            return updateCounter.value;
        }


        // Row {
        
        Item {
            x: 25
            width: 675
            height: parent.height

            Repeater {
                model: 6
                Rectangle {
                    id: rect
                    width: 100
                    height: 100
                    radius: width * 0.5
                    color: Qt.rgba(0,0,0,0.0)
                    z: mouseArea.drag.active ||  mouseArea.pressed ? 2 : 1
                    Rectangle {
                        x: 25
                        y: 25
                        width: 50
                        height: 50
                        color: Qt.rgba(0, 0, 0, 0)
                        radius: index == 0 || index == 5 ? width * 0.1 : width * 0.5
                        border { 
                            width:1; 
                            color: time_scale.point_updated, time_scale.eq_data[index]["enabled"] ? Material.color(Material.Indigo, Material.Shade200) : Material.color(Material.Grey, Material.Shade200)  
                        }
                    }
                    // color: time_scale.eq_data[index]["enabled"] ? Material.color(Material.Indigo, Material.Shade200) : Material.color(Material.Grey, Material.Shade200)  
                    x: time_scale.hzToPixel(time_scale.eq_data[index]["frequency"]) - (width / 2) // offset for square size
                    y: mycanvas.y_at_gain(time_scale.eq_data[index]["gain"]) - (width / 2)
                    property point beginDrag
                    property bool caught: false
                    // border { width:1; color: Material.color(Material.Grey, Material.Shade100)}
                    Drag.active: mouseArea.drag.active

                    Text {
                        anchors.centerIn: parent
                        text: index+1
                        color: "white"
                        font.pixelSize: fontSizeMedium
                    }
                    MouseArea {
                        id: mouseArea
                        anchors.fill: parent
                        drag.target: parent
                        onPressed: {
                            rect.beginDrag = Qt.point(rect.x, rect.y);
                            time_scale.selected_point = index;
                            if (knobs.waiting != "") // mapping on
                            {
                                // pop up knob mapping selector
                                if (index == 0){
                                    // low shelf
                                    mappingPopup.set_mapping_choice(effect, "LSfreq", "FREQUENCY", 
                                        effect, "LSgain", "GAIN", true);
                                }
                                else if (index == 5){
                                    // high shelf
                                    mappingPopup.set_mapping_choice(effect, "HSfreq", "FREQUENCY", 
                                        effect, "HSgain", "GAIN", true);
                                }
                                else {
                                    mappingPopup.set_mapping_choice(effect, "freq"+index, "FREQUENCY", 
                                        effect, "gain"+index, "GAIN", true);
                                }
                            }
                        }
                        onDoubleClicked: {
                            if (index == 0){
                                // low shelf
                                mappingPopup.set_mapping_choice(effect, "LSfreq", "FREQUENCY", 
                                    effect, "LSgain", "GAIN", false);    
                            }
                            else if (index == 5){
                                // high shelf
                                mappingPopup.set_mapping_choice(effect, "HSfreq", "FREQUENCY", 
                                    effect, "HSgain", "GAIN", false);    
                            }
                            else {
                                mappingPopup.set_mapping_choice(effect, "freq"+index, "FREQUENCY", 
                                    effect, "gain"+index, "GAIN", false);
                            }
                        }
                        onReleased: {

                            var in_x = rect.x;
                            var in_y = rect.y;

                            if(!rect.caught) {
                                // clamp to bounds
								in_x = Math.min(Math.max(-(width / 2), in_x), mycanvas.width - (width / 2));
								in_y = Math.min(Math.max(-(width / 2), in_y), mycanvas.height - (width / 2));
                            }
                            var f = time_scale.pixelToHz(in_x + (width / 2)); // offset for square size
                            // console.log("frequency before", time_scale.eq_data[index]["frequency"]);
                            var g = mycanvas.gain_at_y(in_y + (width / 2));
                            // update cache and redraw
                            if (index == 0){
                                // low shelf
                                knobs.ui_knob_change(effect, "LSfreq", f);
                                knobs.ui_knob_change(effect, "LSgain", g);
                            }
                            else if (index == 5){
                                // high shelf
                                knobs.ui_knob_change(effect, "HSfreq", f);
                                knobs.ui_knob_change(effect, "HSgain", g);
                            }
                            else {
                                knobs.ui_knob_change(effect, "freq"+index, f);
                                knobs.ui_knob_change(effect, "gain"+index, g);
                            }
                            // console.log("frequency after", time_scale.eq_data[index]["frequency"]);
                            mycanvas.update_filter_external (index, time_scale.eq_data[index]["frequency"], 
                                time_scale.eq_data[index]["q"], time_scale.eq_data[index]["gain"]);
                            mycanvas.requestPaint();
                        }

                    }
                    ParallelAnimation {
                        id: backAnim
                        SpringAnimation { id: backAnimX; target: rect; property: "x"; duration: 500; spring: 2; damping: 0.2 }
                        SpringAnimation { id: backAnimY; target: rect; property: "y"; duration: 500; spring: 2; damping: 0.2 }
                    }
                }
            }

            Canvas {
                id: mycanvas
                property var filterSections: []
                property var filterFreqs: []
                property bool initDone: false
                property int dbRange: 20 // XXX

                /* cached filter state */
                function filterSection (rate) {
                    this.rate = rate;
                    // this.gain_db = gain_db;
                    // this.s1 = s1;
                    // this.s2 = s2;
                    // float A, B, C, D, A1, B1; // IIR
                    // float x0, y0; // mouse position
                } 

                function setColorAlpha(color, alpha) {
                    return Qt.hsla(color.hslHue, color.hslSaturation, color.hslLightness, alpha)
                }

                // function HoLoFilter (f) {
                //     this.f = f;
                //     // this.q = q;
                //     // this.R = R; // cached resonance (derived from q)
                //     // this.x0 = x0; // mouse pos. vertical middle
                // }

                /* filter parameters */
                function filterFreq (min, max, dflt, warp) {
                    this.min = min;
                    this.max = max;
                    this.dflt = dflt;
                    this.warp = warp;
                }

                function freq_at_x (x, m0_width) {
                    return 20.0 * Math.pow(1000.0, x / m0_width);
                }

                function x_at_freq (f, m0_width) {
                    return Math.round(m0_width * Math.log (f / 20.0) / Math.log (1000.0));
                }


                function gain_at_y (y){
                    var zero_db = height / 2.0;
                    var pixel_per_db = (height /  Math.ceil(2 * dbRange));
                    return (zero_db - y) / pixel_per_db;
                }

                function y_at_gain (gain){
                    var zero_db = height / 2.0;
                    var pixel_per_db = (height /  Math.ceil(2 * dbRange));
                    return zero_db - (pixel_per_db * gain);
                }

                function grid_freq(ctx, fq, hz) { 
                    // x offset
                    var xx = 0 + x_at_freq(fq, width) - 0.5; 
                    ctx.moveTo(xx, 0); 
                    ctx.lineTo(xx, height - 5); 
                    // ctx.stroke(); 
                    ctx.fillText(hz, xx, height - 5); 
                }

                function square(x) {
                    return x * x;
                }

                function grid_line(ctx, fq) { 
                    // var xx = 0 + x_at_freq(fq, width) - 0.5; 
                    // ctx.moveTo(xx, height - 5); 
                    // ctx.lineTo(xx, height - 25); 
                    // ctx.stroke(); 
                }

                function grid_db(ctx, db, tx) { 
                    var max_db = 20 // 24? 18 max set
                    var yy = Math.round(height/2.0 - (height/(max_db*2) * db)); 
                    ctx.moveTo(0, yy) 
                    ctx.lineTo(width, yy); 
                    // ctx.stroke(); 
                    ctx.fillText(tx, 0, yy-5); 
                }


                function update_filter_external (i, freq, q, gain)
                {
                    if (i == 0)
                    {
                        update_iir(mycanvas.filterSections[i], false, freq, q, gain);
                    }
                    else if (i == mycanvas.filterFreqs.length - 1){
                        update_iir(mycanvas.filterSections[i], true, freq, q, gain);
                    }
                    else
                    {
                        update_filter(mycanvas.filterSections[i], freq, q, gain);
                    }
                }

                function update_filter (flt, freq, bw, gain) {
                    // see src/lv2.c  run()
                    var freq_ratio = freq / flt.rate;
                    if (freq_ratio < 0.0002) freq_ratio = 0.0002;
                    if (freq_ratio > 0.4998) freq_ratio = 0.4998;
                    var g = Math.pow (10, 0.05 * gain); // XXX exp2ap()

                    // see src/filters.h  proc()
                    var b = 7.0 * bw * freq_ratio / Math.sqrt (g);
                    flt.s2 = (1.0 - b) / (1.0 + b);
                    flt.s1 = -Math.cos (2 * Math.PI * freq_ratio);
                    flt.s1 *= (1.0 + flt.s2);

                    flt.gain_db = .5 * (g - 1.0) * (1.0 - flt.s2);
                }
                
                function update_iir (flt, hs, freq, bw, gain) {
                    var freq_ratio = freq / flt.rate;
                    var q = 0.2129 + bw / 2.25; // map [2^-4 .. 2^2] to [2^(-3/2) .. 2^(1/2)]
                    if (freq_ratio < 0.0004) freq_ratio = 0.0004;
                    if (freq_ratio > 0.4700) freq_ratio = 0.4700;
                    if (q < 0.25) { q = 0.25; }
                    if (q > 2.0) { q = 2.0; }

                    // compare to src/iir.h
                    var w0 = 2. * Math.PI * (freq_ratio);
                    var _cosW = Math.cos (w0);

                    var A  = Math.pow (10., .025 * gain); // sqrt(gain_as_coeff)
                    var As = Math.sqrt (A);
                    var a  = Math.sin (w0) / 2 * (1 / q);

                    if (hs) { // high shelf
                        var b0 =  A *      ((A + 1) + (A - 1) * _cosW + 2 * As * a);
                        var b1 = -2 * A  * ((A - 1) + (A + 1) * _cosW);
                        var b2 =  A *      ((A + 1) + (A - 1) * _cosW - 2 * As * a);
                        var a0 = (A + 1) -  (A - 1) * _cosW + 2 * As * a;
                        var a1 =  2 *      ((A - 1) - (A + 1) * _cosW);
                        var a2 = (A + 1) -  (A - 1) * _cosW - 2 * As * a;

                        var _b0 = b0 / a0;
                        var _b2 = b2 / a0;
                        var _a2 = a2 / a0;

                        flt.A  = _b0 + _b2;
                        flt.B  = _b0 - _b2;
                        flt.C  = 1.0 + _a2;
                        flt.D  = 1.0 - _a2;
                        flt.A1 = a1 / a0;
                        flt.B1 = b1 / a0;
                    } else { // low shelf
                        var b0 =  A *      ((A + 1) - (A - 1) * _cosW + 2 * As * a);
                        var b1 =  2 * A  * ((A - 1) - (A + 1) * _cosW);
                        var b2 =  A *      ((A + 1) - (A - 1) * _cosW - 2 * As * a);
                        var a0 = (A + 1) +  (A - 1) * _cosW + 2 * As * a;
                        var a1 = -2 *      ((A - 1) + (A + 1) * _cosW);
                        var a2 = (A + 1) +  (A - 1) * _cosW - 2 * As * a;

                        var _b0 = b0 / a0;
                        var _b2 = b2 / a0;
                        var _a2 = a2 / a0;

                        flt.A  = _b0 + _b2;
                        flt.B  = _b0 - _b2;
                        flt.C  = 1.0 + _a2;
                        flt.D  = 1.0 - _a2;
                        flt.A1 = a1 / a0;
                        flt.B1 = b1 / a0;
                    }
                } 

                /* drawing helpers, calculate respone for given frequency */
                function get_filter_response (flt, freq) {
                    var w = 2.0 * Math.PI * freq / flt.rate;
                    var c1 = Math.cos (w);
                    var s1 = Math.sin (w);
                    var c2 = Math.cos (2.0 * w);
                    var s2 = Math.sin (2.0 * w);

                    var x = c2 + flt.s1 * c1 + flt.s2;
                    var y = s2 + flt.s1 * s1;

                    var t1 = Math.hypot(x, y);

                    x += flt.gain_db * (c2 - 1.0);
                    y += flt.gain_db * s2;

                    var t2 = Math.hypot(x, y);

                    return 20.0 * Math.log10 (t2 / t1);
                }

                /* ditto for IIR */
                function get_shelf_response (flt, freq) {
                    var w = 2.0 * Math.PI * freq / flt.rate;
                    var c1 = Math.cos(w);
                    var s1 = Math.sin(w);
                    var A = flt.A * c1 + flt.B1;
                    var B = flt.B * s1;
                    var C = flt.C * c1 + flt.A1;
                    var D = flt.D * s1;
                    return 20.0 * Math.log10 (Math.sqrt ((square(A) + square(B)) * (square(C) + square(D))) / (square(C) + square(D)));
                }

                // function get_highpass_response (Fil4UI *ui, var freq) {
                //     #if 1
                //     /* for 0 < f <= 1/12 fsamp.
                //      * the filter does not [yet] correct for the attenuation
                //      * once  "0dB" reaches fsamp/2 (parameter is clamped
                //      * both in DSP as well as in cb_spn_g_hifreq() here.)
                //      */
                //     var wr = ui->hilo[0].f / freq;
                //     var q = ui->hilo[0].R;
                //     // -20 log (sqrt( (1 + wc / w)^2 - (r * wc / w)^2))
                //     return -10.f * Math.log10 (square(1 + square(wr)) - square(q * wr));
                //     #else // fixed q=0
                //     var w = freq / ui->hilo[0].f;
                //     var v = (w / Math.sqrt (1 + w * w));
                //     return 40.f * Math.log10 (v); // 20 * log(v^2);
                //     #endif
                // }

                // function get_lowpass_response (Fil4UI *ui, var freq) {
                //     #ifdef USE_LOP_FFT
                //     var f = freq / ui->lopfft->freq_per_bin;
                //     uint32_t i = floorf (f);
                //     if (i + 1 >= fftx_bins (ui->lopfft)) {
                //         return fftx_power_to_dB (ui->lopfft->power[fftx_bins (ui->lopfft) - 2]);
                //     }
                //     return fftx_power_to_dB (ui->lopfft->power[i] * (1.f + i - f) + ui->lopfft->power[i+1] * (f - i));
                //     #else
                //     // TODO limit in case SR < 40K, also lop.h w2
                //     var w  = sin (Math.PI * freq /ui->samplerate);
                //     var wc = sin (Math.PI * ui->hilo[1].f /ui->samplerate);
                //     var q = ui->hilo[1].R;
                //     var xhs = 0;
                //     #ifdef LP_EXTRA_SHELF
                //     xhs = get_shelf_response (&ui->lphs, freq);
                //     #endif
                //     return -10.f * Math.log10 (square(1 + square(w/wc)) - square(q * w/wc)) + xhs;
                //     #endif
                // }

                function draw_filters (ctx) {

                    var NCTRL = 6;
                    var shade = 1.0;
                    // var dbRange = 20; 
                    // cairo_set_line_cap(cr, CAIRO_LINE_CAP_BUTT);
                    // cairo_set_line_join(cr, CAIRO_LINE_JOIN_ROUND);
                    var g_gain = 0;

                    // ui->m0_xw = ui->m0_width - 48;
                    // ui->m0_ym = rintf((m0h - 8) * .5f) - .5;
                    // ui->m0_yr = (m0h - 32) / ceilf(2 * ui->ydBrange);
                    // ui->m0_y0 = floor (ui->m0_ym - ui->ydBrange * ui->m0_yr);
                    // ui->m0_y1 = ceil  (ui->m0_ym + ui->ydBrange * ui->m0_yr);

                    // const float xw = ui->m0_xw;
                    // const float ym = ui->m0_ym;
                    // const float yr = ui->m0_yr;
                    // const float x0 = 30;

                    var xw = width;
                    var ym = height / 2.0;
                    var yr = height /  Math.ceil(2 * dbRange);
                    var x0 = 0;
                    // var ny = x_at_freq(.5 * 20000, xw);
                    var ny = x_at_freq(.5 * 48000, xw);

                    /* draw dots for peaking EQ, boxes for shelves */
                    // cairo_set_operator (cr, CAIRO_OPERATOR_ADD);
                    // cairo_set_line_width(cr, 1.0);
                    // for (int j = 0 ; j < NCTRL; ++j) {
                    //     var fshade = shade;
                    //     if (!robtk_cbtn_get_active(ui->btn_enable[j])) {
                    //         fshade = .5;
                    //     }
                    //     const var fq = dial_to_freq(&freqs[j], robtk_dial_get_value (ui->spn_freq[j]));
                    //     const var db = robtk_dial_get_value (ui->spn_gain[j]);

                    //     const var xx = x_at_freq(fq, xw) - .5f;
                    //     const var yy = rintf(ym + .5 - yr * (db + g_gain)) - .5;
                    //     if (ui->dragging == j || (ui->dragging < 0 && ui->hover == j)) {
                    //         cairo_set_source_rgba (cr, c_fil[j][0], c_fil[j][1], c_fil[j][2], fshade);
                    //     } else {
                    //         cairo_set_source_rgba (cr, c_fil[j][0], c_fil[j][1], c_fil[j][2], .6 * fshade);
                    //     }
                    //     if (j == 0 || j == NCTRL - 1) {
                    //         cairo_rectangle (cr, xx - BOXRADIUS, yy - BOXRADIUS, 2 * BOXRADIUS, 2 * BOXRADIUS);
                    //     } else {
                    //         cairo_arc (cr, xx, yy, DOTRADIUS, 0, 2 * Math.PI);
                    //     }
                    //     cairo_fill_preserve (cr);
                    //     cairo_set_source_rgba (cr, c_fil[j][0], c_fil[j][1], c_fil[j][2], .3 * fshade);
                    //     cairo_stroke (cr);

                    //     /* cache position (for drag) */
                    //     ui->flt[j].x0 = x0 + xx;
                    //     ui->flt[j].y0 = yy;
                    // }

                    /* hi/low pass triangles */
                    // {
                    //     const var xx = x_at_freq (ui->hilo[0].f, xw);
                    //     cairo_move_to (cr, xx - .5            , ym + BOXRADIUS);
                    //     cairo_line_to (cr, xx - .5 - BOXRADIUS, ym - BOXRADIUS);
                    //     cairo_line_to (cr, xx - .5 + BOXRADIUS, ym - BOXRADIUS);
                    //     cairo_close_path (cr);
                    //     var fshade = shade;
                    //     if (!robtk_ibtn_get_active(ui->btn_g_hipass)) {
                    //         fshade = .5;
                    //     }
                    //     if (ui->dragging == Ctrl_HPF || (ui->dragging < 0 && ui->hover == Ctrl_HPF)) {
                    //         cairo_set_source_rgba (cr, c_fil[NCTRL][0], c_fil[NCTRL][1], c_fil[NCTRL][2], fshade);
                    //     } else {
                    //         cairo_set_source_rgba (cr, c_fil[NCTRL][0], c_fil[NCTRL][1], c_fil[NCTRL][2], .6 * fshade);
                    //     }
                    //     cairo_fill_preserve (cr);
                    //     cairo_set_source_rgba (cr, c_fil[NCTRL][0], c_fil[NCTRL][1], c_fil[NCTRL][2], .3 * fshade);
                    //     cairo_stroke (cr);
                    //     ui->hilo[0].x0 = x0 + xx;
                    // }

                    // {
                    //     const var xx = x_at_freq (ui->hilo[1].f, xw);
                    //     cairo_move_to (cr, xx - .5            , ym + BOXRADIUS);
                    //     cairo_line_to (cr, xx - .5 - BOXRADIUS, ym - BOXRADIUS);
                    //     cairo_line_to (cr, xx - .5 + BOXRADIUS, ym - BOXRADIUS);
                    //     cairo_close_path (cr);
                    //     var fshade = shade;
                    //     if (!robtk_ibtn_get_active(ui->btn_g_lopass)) {
                    //         fshade = .5;
                    //     }
                    //     if (ui->dragging == Ctrl_LPF || (ui->dragging < 0 && ui->hover == Ctrl_LPF)) {
                    //         cairo_set_source_rgba (cr, c_fil[NCTRL+1][0], c_fil[NCTRL+1][1], c_fil[NCTRL+1][2], fshade);
                    //     } else {
                    //         cairo_set_source_rgba (cr, c_fil[NCTRL+1][0], c_fil[NCTRL+1][1], c_fil[NCTRL+1][2], .6 * fshade);
                    //     }
                    //     cairo_fill_preserve (cr);
                    //     cairo_set_source_rgba (cr, c_fil[NCTRL+1][0], c_fil[NCTRL+1][1], c_fil[NCTRL+1][2], .3 * fshade);
                    //     cairo_stroke (cr);
                    //     ui->hilo[1].x0 = x0 + xx;
                    // }

                    // if (ny < xw) {
                    //     cairo_rectangle (cr, 0, 0, ny, ui->m0_height);
                    //     cairo_clip (cr);
                    // }

                    /* draw filters , hi/lo first (only when dragging)*/
                    // cairo_set_operator (cr, CAIRO_OPERATOR_ADD);
                    ctx.lineWidth = 1.0;

                    // {
                    //     var fshade = shade;
                    //     // if (!robtk_ibtn_get_active(ui->btn_g_hipass)) {
                    //     //     fshade = .5;
                    //     // }
                    //     var yy = ym - yr * g_gain - yr * get_highpass_response (ui, freq_at_x(0, xw));
                    //     cairo_move_to (cr, 0, yy);
                    //     for (int i = 1 ; i < xw && i < ny; ++i) {
                    //         const var xf = freq_at_x(i, xw);
                    //         var y = yr * g_gain;
                    //         y += yr * get_highpass_response (ui, xf);
                    //         cairo_line_to (cr, i, ym - y);
                    //     }
                    //     cairo_set_source_rgba (cr, c_fil[NCTRL][0], c_fil[NCTRL][1], c_fil[NCTRL][2], fshade);
                    //     if (ui->dragging == Ctrl_HPF) {
                    //         cairo_stroke_preserve(cr);
                    //         cairo_line_to (cr, xw, ym);
                    //         cairo_line_to (cr, xw, ym + yr * ui->ydBrange);
                    //         if (yy < ym + yr * ui->ydBrange) {
                    //             cairo_line_to (cr, 0, ym + yr * ui->ydBrange);
                    //         }
                    //         cairo_set_source_rgba (cr, c_fil[NCTRL][0], c_fil[NCTRL][1], c_fil[NCTRL][2], .4 * fshade);
                    //         cairo_fill (cr);
                    //     } else {
                    //         cairo_stroke(cr);
                    //     }
                    // }
                    // {
                    //     var fshade = shade;
                    //     if (!robtk_ibtn_get_active(ui->btn_g_lopass)) {
                    //         fshade = .5;
                    //     }
                    //     cairo_move_to (cr, 0, ym - yr * g_gain - yr * get_lowpass_response (ui, freq_at_x(0, xw)));
                    //     for (int i = 1 ; i < xw && i < ny; ++i) {
                    //         const var xf = freq_at_x(i, xw);
                    //         var y = yr * g_gain;
                    //         y += yr * get_lowpass_response (ui, xf);
                    //         cairo_line_to (cr, i, ym - y);
                    //     }
                    //     cairo_set_source_rgba (cr, c_fil[NCTRL+1][0], c_fil[NCTRL+1][1], c_fil[NCTRL+1][2], fshade);
                    //     if (ui->dragging == Ctrl_LPF) {
                    //         cairo_stroke_preserve(cr);
                    //         var yy = ym - yr * g_gain - yr * get_lowpass_response (ui, freq_at_x(xw, xw));
                    //         if (yy < ym + yr * ui->ydBrange) {
                    //             cairo_line_to (cr, xw, ym + yr * ui->ydBrange);
                    //         }
                    //         cairo_line_to (cr, 0, ym + yr * ui->ydBrange);
                    //         cairo_line_to (cr, 0, ym);
                    //         cairo_set_source_rgba (cr, c_fil[NCTRL+1][0], c_fil[NCTRL+1][1], c_fil[NCTRL+1][2], .4 * fshade);
                    //         cairo_fill (cr);
                    //     } else {
                    //         cairo_stroke(cr);
                    //     }
                    // }

                    // /* draw filters */
                    // for (int j = 0 ; j < NCTRL; ++j) {
                    //     var fshade = shade;
                    //     if (!robtk_cbtn_get_active(ui->btn_enable[j])) {
                    //         fshade = .5;
                    //     }

                    //     cairo_set_source_rgba (cr, c_fil[j][0], c_fil[j][1], c_fil[j][2], fshade);

                    //     for (int i = 0 ; i < xw && i < ny; ++i) {
                    //         const var xf = freq_at_x(i, xw);
                    //         var y = yr;
                    //         if (j == 0) {
                    //             y *= get_shelf_response (&ui->flt[j], xf);
                    //         } else if (j == NCTRL -1) {
                    //             y *= get_shelf_response (&ui->flt[j], xf);
                    //         } else {
                    //             y *= get_filter_response (&ui->flt[j], xf);
                    //         }
                    //         y += yr * g_gain;
                    //         if (i == 0) {
                    //             cairo_move_to (cr, i, ym - y);
                    //         } else {
                    //             cairo_line_to (cr, i, ym - y);
                    //         }
                    //     }
                    //     if (ui->dragging == j) {
                    //         cairo_stroke_preserve(cr);
                    //         cairo_line_to (cr, xw, ym - yr * g_gain);
                    //         cairo_line_to (cr, 0, ym - yr * g_gain);
                    //         cairo_set_source_rgba (cr, c_fil[j][0], c_fil[j][1], c_fil[j][2], 0.4 * fshade);
                    //         cairo_fill (cr);
                    //     } else {
                    //         cairo_stroke(cr);
                    //     }
                    // }

                    // /* zero line - mask added colors */
                    // cairo_set_operator (cr, CAIRO_OPERATOR_OVER);
                    // cairo_set_line_width(cr, 1.0);
                    // CairoSetSouerceRGBA(c_g60);
                    // cairo_move_to (cr, 0, ym - yr * g_gain);
                    // cairo_line_to (cr, xw -1 , ym - yr * g_gain);
                    // cairo_stroke(cr);

                    /* draw total */
                    ctx.lineWidth = 2 * shade;
                    // XXX
                    ctx.beginPath();
                    // cairo_set_source_rgba (cr, 1.0, 1.0, 1.0, shade);
                    for (var i = 0 ; i < xw && i < ny; ++i) {
                        var xf = freq_at_x(i, xw);
                        var y = yr * g_gain;
                        for (var j = 0 ; j < NCTRL; ++j) {
                            // if (!robtk_cbtn_get_active(ui->btn_enable[j])) continue;
                            // TODO check if enabled
                            if (time_scale.eq_data[j]["enabled"])
                            {
                                if (j == 0) {
                                    y += yr * get_shelf_response (mycanvas.filterSections[j], xf);
                                } else if (j == NCTRL -1) {
                                    y += yr * get_shelf_response (mycanvas.filterSections[j], xf);
                                } else {
                                    y += yr * get_filter_response (mycanvas.filterSections[j], xf);
                                }
                            }
                        }
                        // if (robtk_ibtn_get_active(ui->btn_g_hipass)) {
                        //     y += yr * get_highpass_response (ui, xf);
                        // }
                        // if (robtk_ibtn_get_active(ui->btn_g_lopass)) {
                        //     y += yr * get_lowpass_response (ui, xf);
                        // }
                        if (i == 0) {
                            // TODO optimize '0'/moveto out of the loop
                            ctx.moveTo(i, ym - y);
                            // console.log("move to", i, ym - y, height);
                        } else {
                            // ctx.moveTo(i, ym - y);
                            ctx.lineTo(i, ym - y);
                            // console.log("line to", i, ym - y, height);
                        }
                    }
                    // cairo_set_operator (cr, CAIRO_OPERATOR_ADD);
                    // cairo_stroke_preserve(cr);
                    // cairo_set_operator (cr, CAIRO_OPERATOR_ADD);
                    //
                    // ctx.strokeStyle = Qt.rgba(0.1,0.1,0.1,0.1);
                    ctx.stroke();
                    ctx.lineTo(xw, ym - yr * g_gain);
                    ctx.lineTo(0, ym - yr * g_gain);
                    ctx.fileStyle = Qt.rgba(0.5, 0.5, 0.5, 0.33 * shade);
                    ctx.fill();
                }

                anchors {
                    top: parent.top
                    right:  parent.right
                    bottom:  parent.bottom
                }
                width: time_scale.active_width
                onPaint: {
                    if (!mycanvas.initDone) {
                        // init filters
                        Math.log10 = Math.log10 || function(x) {
                            return Math.log(x) * Math.LOG10E;
                        };

                        if (!Math.hypot) Math.hypot = function() {
                            var y = 0, i = arguments.length;
                            while (i--) y += arguments[i] * arguments[i];
                            return Math.sqrt(y);
                        };

                        mycanvas.filterSections = [new filterSection(48000), 
                                    new filterSection(48000), 
                                    new filterSection(48000), 
                                    new filterSection(48000), 
                                    new filterSection(48000), 
                                    new filterSection(48000), 
                                    new filterSection(48000), 
                                    new filterSection(48000)];

                        mycanvas.filterFreqs = [ new filterFreq(25,   400,    80,  16), // LS
                                        new filterFreq(  20,  2000,   160, 100),
                                        new filterFreq(  40,  4000,   397, 100),
                                        new filterFreq( 100, 10000,  1250, 100),
                                        new filterFreq( 200, 20000,  2500, 100),
                                        new filterFreq(1000, 16000,  8000,  16) // HS
                                    ]; /*min    max   dflt*/

                        for (var i = 0; i < time_scale.eq_data.length; i++) {
                            mycanvas.update_filter_external (i, 
                            time_scale.eq_data[i]["frequency"], 
                            time_scale.eq_data[i]["q"], 
                            time_scale.eq_data[i]["gain"]);
                        }
                                    // for (var i = 0; i < mycanvas.filterFreqs.length; i++) {
                        //     if (i == 0)
                        //     {
                        //         update_iir(mycanvas.filterSections[i], false, mycanvas.filterFreqs[i].dflt, 1, 0.0);
                        //     }
                        //     else if (i == mycanvas.filterFreqs.length - 1){
                        //         update_iir(mycanvas.filterSections[i], true, mycanvas.filterFreqs[i].dflt, 1, 0.0);
                        //     }
                        //     else
                        //     {
                        //         update_filter(mycanvas.filterSections[i], mycanvas.filterFreqs[i].dflt, 0.1, 2.0);
                        //     }
                        // }
                        mycanvas.initDone = true;
                    
                    }
                    var ctx = getContext("2d");
                    // draw the grid
                    ctx.fillStyle = Material.background; //Qt.rgba(1, 1, 0, 1);
                    // ctx.clearRect(0, 0, width, height);
                    ctx.fillRect(0, 0, width, height);
                    // draw beat snap lines  
                    // every second
                    ctx.fillStyle = Material.accent; //, 0.3);//Qt.rgba(0.1, 0.1, 0.1, 1);
                    // ctx.strokeStyle = '#000000';
                    ctx.strokeStyle = Qt.rgba(0.1,0.1,0.1,1);//setColorAlpha(Material.accent, 0.8);//Qt.rgba(0.1, 0.1, 0.1, 1);
                    // ctx.fillRect(0, 0, 1, height);
                    //
                    // vertical lines, showing frequency
                    // grid_freq(ctx, 20, "20");
                    ctx.beginPath();
                    ctx.font = "14px sans-serif"
                    ctx.lineWidth = 1.0;
                    grid_line(ctx, 25);
                    grid_line(ctx, 31.5);
                    grid_freq(ctx, 40, "40");
                    grid_line(ctx, 50);
                    grid_line(ctx, 63);
                    grid_freq(ctx, 80, "80");
                    grid_line(ctx, 100);
                    grid_line(ctx, 125);
                    grid_freq(ctx, 160, "160");
                    grid_line(ctx, 200);
                    grid_line(ctx, 250);
                    grid_freq(ctx, 315, "315");
                    grid_line(ctx, 400);
                    grid_line(ctx, 500);
                    grid_freq(ctx, 630, "630");
                    grid_line(ctx, 800);
                    grid_line(ctx, 1000);
                    grid_freq(ctx, 1250, "1K25");
                    grid_line(ctx, 1600);
                    grid_line(ctx, 2000);
                    grid_freq(ctx, 2500, "2K5");
                    grid_line(ctx, 3150);
                    grid_line(ctx, 4000);
                    grid_freq(ctx, 5000, "5K");
                    grid_line(ctx, 6300);
                    grid_line(ctx, 8000);
                    grid_freq(ctx, 10000, "10K");
                    grid_line(ctx, 12500);
                    grid_line(ctx, 16000);
                    grid_freq(ctx, 20000, "20K");
                    // horizontal lines show db
                    // grid_db(ctx, 0, "0");
                    for (var i = -18; i < 19; i=i+6) {
                        grid_db(ctx, i, i.toString());
                    }
                    ctx.stroke(); 


                    // draw the curve given the control points
                    // iterate over control points?

                    if (time_scale.eq_enabled){
                        ctx.strokeStyle = Material.accent;//setColorAlpha(Material.accent, 0.8);//Qt.rgba(0.1, 0.1, 0.1, 1);
                        ctx.fillStyle = setColorAlpha(Material.accent, 0.3);//Qt.rgba(0.1, 0.1, 0.1, 1);
                    }
                    else {
                        ctx.strokeStyle = Qt.rgba(0.6, 0.6, 0.6, 0.5);//setColorAlpha(Material.accent, 0.8);//Qt.rgba(0.1, 0.1, 0.1, 1);
                        ctx.fillStyle = Qt.rgba(0.6, 0.6, 0.6, 0.3); //setColorAlpha(Material.BlueGrey, 0.3);
                    }
                    // ctx.strokeStyle
                    draw_filters(ctx)

                }
                DropArea {
                    anchors.fill: parent
                    onEntered: drag.source.caught = true;
                    onExited: drag.source.caught = false;
                }
            }
            // Rectangle {
            //     anchors {
            //         top: parent.top
            //         right:  parent.right
            //         bottom:  parent.bottom
            //     }
            //     width: parent.width / 2
            //     color: "gold"
            //     DropArea {
            //         anchors.fill: parent
            //         onEntered: drag.source.caught = true;
            //         onExited: drag.source.caught = false;
            //     }
            // }
            Label {
                text: "HZ"
                font.pixelSize: 20
                z: 2
                anchors.horizontalCenter: mycanvas.horizontalCenter
                anchors.top: mycanvas.bottom
                color: "grey"
            }

            Label {
                text: "GAIN (dB)"
                font.pixelSize: 20
                height:30
                width: 30
                // x: 200
                z: 2
                anchors.verticalCenter: mycanvas.verticalCenter
                anchors.right: mycanvas.left
                rotation : 270
                color: "grey"
            }
        }
        PolyFrame {
            // background: Material.background
            x: 710
            width:1220
            height:parent.height
            // Material.elevation: 2

            Column {
                width:120
                spacing: 20
                height:parent.height

                GlowingLabel {
                    color: "#ffffff"
                    text: qsTr("GAIN")
                }

                MixerDial {
                    effect: "reverb"
                    param: "gain"
                }

                Switch {
                    text: qsTr("EQ ON")
					font.pixelSize: fontSizeMedium
                    bottomPadding: 0
                    // height: 20
                    // implicitWidth: 100
                    width: 150
                    leftPadding: 0
                    topPadding: 0
                    rightPadding: 0
                    checked: eq_enabled
                    onClicked: {
                        knobs.ui_knob_change(effect, "enable", checked | 0); // force to int
                        mycanvas.requestPaint();
                    }
                }

                Label {
                    width: parent.width
                    anchors.left: parent.left
                    anchors.right: parent.right
                    text: qsTr("BAND")
                    font.pixelSize: baseFontSize
                }

                Switch {
                    text: time_scale.selected_point + 1
					font.pixelSize: baseFontSize
                    bottomPadding: 0
                    width: 100
                    leftPadding: 0
                    topPadding: 0
                    rightPadding: 0
                    checked: time_scale.eq_data[time_scale.selected_point]["enabled"]
                    onClicked: {
                        // time_scale.eq_data[time_scale.selected_point]["enabled"] = checked;
                        if (time_scale.selected_point == 0){
                            knobs.ui_knob_change(effect, "LSsec", checked | 0); // force to int
                        } else if (time_scale.selected_point == 5){
                            knobs.ui_knob_change(effect, "HSsec", checked | 0); // force to int
                        } else {
                            knobs.ui_knob_change(effect, "sec"+time_scale.selected_point, checked | 0); // force to int
                        }
                        time_scale.point_updated++; 
                        mycanvas.requestPaint();
                    }
                }

                GlowingLabel {
                    color: "#ffffff"
                    text: qsTr("Q")
                }

                Dial {
                    id: control
                    // property string param
                    // property string effect: "mixer"
                    // property string textOverride: control.value.toFixed(1)
                    width: 75
                    height: 75
                    from: 0.1
                    live: false
                    Label {
                        color: "#ffffff"
                        text: control.value.toFixed(1)
                        font.pixelSize: 20 * 2
                        anchors.centerIn: parent
                    }
                    onPressedChanged: {
                        if (pressed === false)
                        {
                            // knobs.ui_knob_change(effect, param, control.value)
                            // time_scale.eq_data[time_scale.selected_point]["q"] = control.value
                            // console.log("setting q", control.value);
                            if (time_scale.selected_point == 0){
                                knobs.ui_knob_change(effect, "LSq", 
                                        control.value);
                            } else if (time_scale.selected_point == 5){
                                knobs.ui_knob_change(effect, "HSq", 
                                        control.value);
                            } else {
                                knobs.ui_knob_change(effect, "q"+time_scale.selected_point, 
                                        control.value);
                            }
                            mycanvas.update_filter_external (time_scale.selected_point, 
                                time_scale.eq_data[time_scale.selected_point]["frequency"], 
                                time_scale.eq_data[time_scale.selected_point]["q"], 
                                time_scale.eq_data[time_scale.selected_point]["gain"]);
                            mycanvas.requestPaint();
                        }
                    }
                    // onPressedChanged: {
                        // console.warn("set knob mapping")
                        // if we're in set control mode, then set this control
                        // python variable in qml context
                        // if (knobs.waiting != "") // left or right
                        // {
                        //     knobs.map_parameter_to_encoder(effect, param)    
                        //     console.warn("set knob mapping")
                        // }
                    // }
                    // Layout.minimumHeight: 64
                    value: time_scale.eq_data[time_scale.selected_point]["q"]
                    // Layout.minimumWidth: 64
                    // Layout.maximumHeight: 128
                    // Layout.fillHeight: true
                    // Layout.preferredWidth: 128
                    stepSize: 0.01
                    to: 4
                    // Layout.preferredHeight: 128
                    // Layout.alignment: Qt.AlignHCenter
                    // Layout.maximumWidth: 128
                }
            }
        }

        // }
    }
// }

