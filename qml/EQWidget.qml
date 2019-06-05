import QtQuick 2.4
import QtQuick.Window 2.2
import QtQuick.Controls 2.3
import QtQuick.Controls.Material 2.3

ApplicationWindow {

    Material.theme: Material.Dark
    Material.primary: Material.Green
    Material.accent: Material.Pink
    width: 1200
    height: 700
    title: "Drag & drop example"
    visible: true

    Item {
        id: time_scale
        width: 1200
        height: 550
        property bool snapping: true
        property bool synced: true
        property int division: 4
        property int bars: 1
        property int active_width: 900
        property int num_delays: 1
        property string current_parameter: "LEVEL"
        property int max_delay_length: 30
        property var delay_data: [{"time": 0.25, "LEVEL": 0.5, "TONE": 0.8, "FEEDBACK":0.2},
            {"time": 0.5, "LEVEL": 0.4, "TONE": 0.8, "FEEDBACK":0.2},
            {"time": 0.75, "LEVEL": 0.3, "TONE": 0.8, "FEEDBACK":0.2},
            {"time": 0.85, "LEVEL": 0.2, "TONE": 0.8, "FEEDBACK":0.2}]
        property var delay_colors: [Material.Pink, Material.Purple, Material.LightBlue, Material.Amber]
        // PPQN * bars
        //
        function nearestDivision(x) {
            // given pixel find nearest pixel for division
            var grid_width = active_width/time_scale.division;
            return Math.round(x / grid_width) * grid_width;
        }

        function beatToPixel(beat) {
            // given factional beat find pixel 
            return beat * active_width / time_scale.bars;
        }

        function pixelToBeat(x) {
            // given factional beat find pixel 
            return x * time_scale.bars / active_width;
        }

        function valueToPixel(index) {
            // work out a y pixel from level / tone / feedback value
            return (1 - delay_data[index][current_parameter]) * height; // TODO values scaling?
        }

        function pixelToValue(index, y) {
            // given a y pixel set level / tone / feedback value
            delay_data[index][current_parameter] = 1 - (y / height);
        }

        function hzToPixel(t) {
            // log / inv log 0-max delay length seconds TODO
            return t * active_width / max_delay_length;
        }

        function pixelToHz(x) {
            return x * max_delay_length / active_width;
        }


        // Row {
        PolyFrame {
            // background: Material.background
            width:200
            height:parent.height
            // Material.elevation: 2

            Column {
                width:200
                spacing: 10
                height:parent.height

                SpinBox {
                    from: 1
                    value: 1
                    to: 4
                    onValueModified: {
                        time_scale.num_delays = value;
                    }
                }

                Switch {
                    text: qsTr("SNAPPING")
                    bottomPadding: 0
                    width: 200
                    leftPadding: 0
                    topPadding: 0
                    rightPadding: 0
                    checked: true
                    enabled: time_scale.synced
                    onClicked: {
                        time_scale.snapping = checked
                    }
                }
                Switch {
                    text: qsTr("TEMPO SYNC")
                    bottomPadding: 0
                    width: 200
                    leftPadding: 0
                    topPadding: 0
                    rightPadding: 0
                    checked: true
                    onClicked: {
                        time_scale.synced = checked
                        mycanvas.requestPaint();
                    }
                }
                ComboBox {
                    width: 140
                    enabled: time_scale.synced
                    textRole: "key"
                    model: ListModel {
                        ListElement { key: "1/4"; value: 4 }
                        ListElement { key: "1/3"; value: 3 }
                        ListElement { key: "1/8"; value: 8 }
                        ListElement { key: "1/16"; value: 16 }
                        ListElement { key: "1/32"; value: 32 }
                    }
                    onActivated: {
                        time_scale.division = model.get(index).value;
                        mycanvas.requestPaint();
                    }
                }

                ComboBox {
                    width: 140
                    model: ["LEVEL", "TONE", "FEEDBACK"]
                    onActivated: {
                        console.debug(model[index]);
                        time_scale.current_parameter = model[index];
                    }
                }
            }
        }
        
        Item {
            x: 300
            width: 900
            height: parent.height

            Repeater {
                model: 4
                Rectangle {
                    id: rect
                    width: 50
                    height: 50
                    z: mouseArea.drag.active ||  mouseArea.pressed ? 2 : 1
                    color: Material.color(time_scale.delay_colors[index])
                    x: time_scale.hzToPixel(time_scale.delay_data[index]["time"])
                    y: time_scale.valueToPixel(index)
                    property point beginDrag
                    property bool caught: false
                    // border { width:1; color: Material.color(Material.Grey, Material.Shade100)}
                    radius: 5
                    Drag.active: mouseArea.drag.active

                    Text {
                        anchors.centerIn: parent
                        text: index
                        color: "white"
                    }
                    MouseArea {
                        id: mouseArea
                        anchors.fill: parent
                        drag.target: parent
                        onPressed: {
                            rect.beginDrag = Qt.point(rect.x, rect.y);
                        }
                        onReleased: {
                            if(!rect.caught) {
                                backAnimX.from = rect.x;
                                backAnimX.to = beginDrag.x;
                                backAnimY.from = rect.y;
                                backAnimY.to = beginDrag.y;
                                backAnim.start()
                            }
                            else 
                            {
                                if(time_scale.snapping && time_scale.synced) {
                                    rect.x = time_scale.nearestDivision(rect.x);
                                }
                                time_scale.delay_data[index]["time"] = time_scale.pixelToHz(rect.x);
                                time_scale.pixelToValue(index, rect.y);
                            }
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

                /* cached filter state */
                function filterSection (rate) {
                    this.rate = rate;
                    // this.gain_db = gain_db;
                    // this.s1 = s1;
                    // this.s2 = s2;
                    // float A, B, C, D, A1, B1; // IIR
                    // float x0, y0; // mouse position
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

                function grid_freq(ctx, fq, hz) { 
                    // x offset
                    var xx = 0 + x_at_freq(fq, width) - 0.5; 
                    ctx.moveTo(xx, 0); 
                    ctx.lineTo(xx, height - 5); 
                    ctx.stroke(); 
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
                    ctx.stroke(); 
                    ctx.fillText(tx, 0, yy-5); 
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

                    // shade based on enabled TODO
                    var NCTRL = 6;
                    var shade = 1.0;
                    var dbRange = 20; // XXX put this somewhere else
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
                    var ny = x_at_freq(.5 * 20000, xw);

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
                    ctx.lineWidth = 2.0 * shade;
                    // XXX
                    ctx.beginPath();
                    // cairo_set_source_rgba (cr, 1.0, 1.0, 1.0, shade);
                    // ctx.strokeStyle
                    for (var i = 0 ; i < xw && i < ny; ++i) {
                        var xf = freq_at_x(i, xw);
                        var y = yr * g_gain;
                        for (var j = 0 ; j < NCTRL; ++j) {
                            // if (!robtk_cbtn_get_active(ui->btn_enable[j])) continue;
                            // TODO check if enabled
                            if (j == 0) {
                                y += yr * get_shelf_response (mycanvas.filterSections[j], xf);
                            } else if (j == NCTRL -1) {
                                y += yr * get_shelf_response (mycanvas.filterSections[j], xf);
                            } else {
                                y += yr * get_filter_response (mycanvas.filterSections[j], xf);
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
                            console.log("move to", i, ym - y, height);
                        } else {
                            ctx.moveTo(i, ym - y);
                            console.log("move to", i, ym - y, height);
                        }
                    }
                    // cairo_set_operator (cr, CAIRO_OPERATOR_ADD);
                    // cairo_stroke_preserve(cr);
                    // cairo_set_operator (cr, CAIRO_OPERATOR_ADD);
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
                    if (!mycanvas.filter_inited) {
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
                        for (var i = 0; i < mycanvas.filterFreqs.length; i++) {
                            if (i == 0)
                            {
                                update_iir(mycanvas.filterSections[i], false, mycanvas.filterFreqs[i].dflt, 1, 0.0)
                            }
                            else if (i == mycanvas.filterFreqs.length - 1){
                                update_iir(mycanvas.filterSections[i], true, mycanvas.filterFreqs[i].dflt, 1, 1.2)
                            }
                            else
                            {
                                update_filter(mycanvas.filterSections[i], mycanvas.filterFreqs[i].dflt, 1, 0.0)
                            }
                        }
                    
                    }
                    var ctx = getContext("2d");
                    // draw the grid
                    ctx.fillStyle = Material.background; //Qt.rgba(1, 1, 0, 1);
                    ctx.fillRect(0, 0, width, height);
                    // draw beat snap lines  
                    // every second
                    ctx.fillStyle = Material.accent;//Qt.rgba(0.1, 0.1, 0.1, 1);

                    // ctx.fillRect(0, 0, 1, height);
                    //
                    // vertical lines, showing frequency
                    // grid_freq(ctx, 20, "20");
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


                    // for (var i = 1; i < time_scale.max_delay_length+1; i++) {
                    //     var x = (width/time_scale.max_delay_length)*i
                    //     ctx.fillRect(x, 0, 1, height);
                    //     // var x = width/Math.log(time_scale.max_delay_length+1)*Math.log(i)
                    //     // ctx.fillRect(x, 0, 1, height);
                    //     if (i < 4)
                    //     {
                    //         ctx.fillText(i-1, x+2, height - 10);
                    //     }
                    // }

                    // draw the curve given the control points
                    // iterate over control points?
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
                text: time_scale.current_parameter
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

        // }
    }
}

