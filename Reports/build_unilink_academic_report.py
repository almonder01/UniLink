from __future__ import annotations

from pathlib import Path

from docx import Document
from docx.enum.section import WD_SECTION_START
from docx.enum.table import WD_ALIGN_VERTICAL, WD_TABLE_ALIGNMENT
from docx.enum.text import WD_ALIGN_PARAGRAPH
from docx.oxml import OxmlElement
from docx.oxml.ns import qn
from docx.shared import Inches, Pt, RGBColor


OUT_DIR = Path(__file__).resolve().parent
DOCX_PATH = OUT_DIR / "UniLink_Academic_Report.docx"
TEXT_PATH = OUT_DIR / "UniLink_Academic_Report_Text.md"

BLUE = RGBColor(0x2E, 0x74, 0xB5)
DARK_BLUE = RGBColor(0x1F, 0x4D, 0x78)
MUTED = RGBColor(0x66, 0x6F, 0x7A)
BLACK = RGBColor(0x00, 0x00, 0x00)
LIGHT_FILL = "F2F4F7"
CALLOUT_FILL = "EAF2F8"
CODE_FILL = "F6F8FA"
WHITE = "FFFFFF"


def set_run_font(run, name="Calibri", size=None, color=None, bold=None, italic=None):
    run.font.name = name
    run._element.rPr.rFonts.set(qn("w:ascii"), name)
    run._element.rPr.rFonts.set(qn("w:hAnsi"), name)
    if size is not None:
        run.font.size = Pt(size)
    if color is not None:
        run.font.color.rgb = color
    if bold is not None:
        run.bold = bold
    if italic is not None:
        run.italic = italic


def set_cell_shading(cell, fill):
    tc_pr = cell._tc.get_or_add_tcPr()
    shd = tc_pr.find(qn("w:shd"))
    if shd is None:
        shd = OxmlElement("w:shd")
        tc_pr.append(shd)
    shd.set(qn("w:fill"), fill)


def set_cell_margins(cell, top=80, start=120, bottom=80, end=120):
    tc = cell._tc
    tc_pr = tc.get_or_add_tcPr()
    tc_mar = tc_pr.first_child_found_in("w:tcMar")
    if tc_mar is None:
        tc_mar = OxmlElement("w:tcMar")
        tc_pr.append(tc_mar)
    for margin_name, margin_value in {
        "top": top,
        "start": start,
        "bottom": bottom,
        "end": end,
    }.items():
        node = tc_mar.find(qn(f"w:{margin_name}"))
        if node is None:
            node = OxmlElement(f"w:{margin_name}")
            tc_mar.append(node)
        node.set(qn("w:w"), str(margin_value))
        node.set(qn("w:type"), "dxa")


def set_cell_width(cell, width_dxa):
    tc_pr = cell._tc.get_or_add_tcPr()
    tc_w = tc_pr.find(qn("w:tcW"))
    if tc_w is None:
        tc_w = OxmlElement("w:tcW")
        tc_pr.append(tc_w)
    tc_w.set(qn("w:w"), str(width_dxa))
    tc_w.set(qn("w:type"), "dxa")


def set_table_width(table, width_dxa=9360, indent_dxa=120):
    tbl = table._tbl
    tbl_pr = tbl.tblPr
    tbl_w = tbl_pr.find(qn("w:tblW"))
    if tbl_w is None:
        tbl_w = OxmlElement("w:tblW")
        tbl_pr.append(tbl_w)
    tbl_w.set(qn("w:w"), str(width_dxa))
    tbl_w.set(qn("w:type"), "dxa")

    tbl_ind = tbl_pr.find(qn("w:tblInd"))
    if tbl_ind is None:
        tbl_ind = OxmlElement("w:tblInd")
        tbl_pr.append(tbl_ind)
    tbl_ind.set(qn("w:w"), str(indent_dxa))
    tbl_ind.set(qn("w:type"), "dxa")


def set_table_borders(table, color="D7DCE2", size="4"):
    tbl_pr = table._tbl.tblPr
    borders = tbl_pr.first_child_found_in("w:tblBorders")
    if borders is None:
        borders = OxmlElement("w:tblBorders")
        tbl_pr.append(borders)
    for edge in ("top", "left", "bottom", "right", "insideH", "insideV"):
        tag = f"w:{edge}"
        elem = borders.find(qn(tag))
        if elem is None:
            elem = OxmlElement(tag)
            borders.append(elem)
        elem.set(qn("w:val"), "single")
        elem.set(qn("w:sz"), size)
        elem.set(qn("w:space"), "0")
        elem.set(qn("w:color"), color)


def clear_table_borders(table):
    tbl_pr = table._tbl.tblPr
    borders = tbl_pr.first_child_found_in("w:tblBorders")
    if borders is None:
        borders = OxmlElement("w:tblBorders")
        tbl_pr.append(borders)
    for edge in ("top", "left", "bottom", "right", "insideH", "insideV"):
        tag = f"w:{edge}"
        elem = borders.find(qn(tag))
        if elem is None:
            elem = OxmlElement(tag)
            borders.append(elem)
        elem.set(qn("w:val"), "nil")


def paragraph_border_bottom(paragraph, color="2E74B5", size="8"):
    p = paragraph._p
    p_pr = p.get_or_add_pPr()
    borders = p_pr.find(qn("w:pBdr"))
    if borders is None:
        borders = OxmlElement("w:pBdr")
        p_pr.append(borders)
    bottom = borders.find(qn("w:bottom"))
    if bottom is None:
        bottom = OxmlElement("w:bottom")
        borders.append(bottom)
    bottom.set(qn("w:val"), "single")
    bottom.set(qn("w:sz"), size)
    bottom.set(qn("w:space"), "4")
    bottom.set(qn("w:color"), color)


def configure_document(doc):
    section = doc.sections[0]
    section.start_type = WD_SECTION_START.NEW_PAGE
    section.top_margin = Inches(1)
    section.bottom_margin = Inches(1)
    section.left_margin = Inches(1)
    section.right_margin = Inches(1)

    styles = doc.styles
    normal = styles["Normal"]
    normal.font.name = "Calibri"
    normal._element.rPr.rFonts.set(qn("w:ascii"), "Calibri")
    normal._element.rPr.rFonts.set(qn("w:hAnsi"), "Calibri")
    normal.font.size = Pt(11)
    normal.paragraph_format.space_after = Pt(6)
    normal.paragraph_format.line_spacing = 1.10

    for style_name, size, color, before, after in [
        ("Heading 1", 16, BLUE, 16, 8),
        ("Heading 2", 13, BLUE, 12, 6),
        ("Heading 3", 12, DARK_BLUE, 8, 4),
    ]:
        style = styles[style_name]
        style.font.name = "Calibri"
        style._element.rPr.rFonts.set(qn("w:ascii"), "Calibri")
        style._element.rPr.rFonts.set(qn("w:hAnsi"), "Calibri")
        style.font.size = Pt(size)
        style.font.color.rgb = color
        style.font.bold = True
        style.paragraph_format.space_before = Pt(before)
        style.paragraph_format.space_after = Pt(after)
        style.paragraph_format.keep_with_next = True

    for style_name in ["List Bullet", "List Number"]:
        style = styles[style_name]
        style.font.name = "Calibri"
        style._element.rPr.rFonts.set(qn("w:ascii"), "Calibri")
        style._element.rPr.rFonts.set(qn("w:hAnsi"), "Calibri")
        style.font.size = Pt(11)
        style.paragraph_format.left_indent = Inches(0.5)
        style.paragraph_format.first_line_indent = Inches(-0.25)
        style.paragraph_format.space_after = Pt(8)
        style.paragraph_format.line_spacing = 1.167

    header = section.header.paragraphs[0]
    header.text = "UniLink Mobile Application Report"
    header.alignment = WD_ALIGN_PARAGRAPH.RIGHT
    set_run_font(header.runs[0], size=9, color=MUTED)

    footer = section.footer.paragraphs[0]
    footer.text = "Prepared for academic submission"
    footer.alignment = WD_ALIGN_PARAGRAPH.CENTER
    set_run_font(footer.runs[0], size=9, color=MUTED)


def add_title_page(doc):
    doc.add_paragraph()
    p = doc.add_paragraph()
    p.alignment = WD_ALIGN_PARAGRAPH.CENTER
    run = p.add_run("UniLink Mobile Application Report")
    set_run_font(run, size=24, color=BLACK, bold=True)

    p = doc.add_paragraph()
    p.alignment = WD_ALIGN_PARAGRAPH.CENTER
    run = p.add_run("Map Integration, Multimedia, Data Persistence, and User Engagement Features")
    set_run_font(run, size=13, color=MUTED)

    p = doc.add_paragraph()
    p.alignment = WD_ALIGN_PARAGRAPH.CENTER
    run = p.add_run("Formal Academic Project Documentation")
    set_run_font(run, size=11, color=BLUE, bold=True)

    doc.add_paragraph()
    rule = doc.add_paragraph()
    paragraph_border_bottom(rule, color="2E74B5", size="8")

    metadata = [
        ("Application Name", "UniLink"),
        ("Platform", "Flutter mobile application"),
        ("Backend", "Firebase Firestore"),
        ("Report Scope", "Compulsory features, implementation explanation, screenshots, and programming concepts"),
        ("Prepared By", "[Student Name]"),
        ("Student ID", "[Student ID]"),
        ("Submission Date", "[Insert Date]"),
    ]
    table = doc.add_table(rows=len(metadata), cols=2)
    table.alignment = WD_TABLE_ALIGNMENT.CENTER
    set_table_width(table, 7600, 880)
    set_table_borders(table, color="D7DCE2")
    for row, (label, value) in zip(table.rows, metadata):
        row.cells[0].text = label
        row.cells[1].text = value
        for i, cell in enumerate(row.cells):
            set_cell_margins(cell, top=100, bottom=100, start=140, end=140)
            set_cell_width(cell, 2200 if i == 0 else 5400)
            cell.vertical_alignment = WD_ALIGN_VERTICAL.CENTER
            if i == 0:
                set_cell_shading(cell, LIGHT_FILL)
                for paragraph in cell.paragraphs:
                    for run in paragraph.runs:
                        set_run_font(run, size=10.5, bold=True, color=DARK_BLUE)
            else:
                for paragraph in cell.paragraphs:
                    for run in paragraph.runs:
                        set_run_font(run, size=10.5, color=BLACK)

    doc.add_paragraph()
    add_callout(
        doc,
        "Report note",
        "The screenshot areas in this document are intentionally written as figure captions and placeholders. "
        "They are ready for the final screenshots to be inserted after the app is run on the target device.",
    )
    doc.add_page_break()


def add_front_matter(doc):
    add_heading(doc, "Contents", 1)
    contents = [
        "1. Introduction",
        "2. System Overview",
        "3. Screenshot Requirements and Figure Captions",
        "4. Compulsory Feature 1: Map Integration",
        "5. Compulsory Feature 2: Multimedia Integration",
        "6. Compulsory Feature 3: Data Persistence",
        "7. Additional Implemented Features",
        "8. Analysis of Related Programming Concepts",
        "9. Data Collections and Persistence Design",
        "10. Evaluation Against Requirements",
        "11. Limitations and Future Improvements",
        "12. Conclusion",
    ]
    for item in contents:
        add_bullet(doc, item)

    add_heading(doc, "Abstract", 1)
    add_para(
        doc,
        "This report presents UniLink, a Flutter-based mobile application developed for university club engagement and "
        "event management. The application allows students to discover clubs, follow clubs, register for events, interact "
        "with posts, save content, receive notifications, and communicate through direct messages and club rooms. Club "
        "managers can manage club profiles, events, posts, members, membership requests, registration approvals, payments, "
        "and event analytics. The report explains how the project implements map integration, multimedia integration, and "
        "data persistence using Flutter, flutter_map, latlong2, image picking, Base64 media storage, and Firebase Firestore.",
    )
    doc.add_page_break()


def add_heading(doc, text, level=1):
    return doc.add_heading(text, level=level)


def add_para(doc, text, bold_prefix=None):
    p = doc.add_paragraph()
    if bold_prefix and text.startswith(bold_prefix):
        run = p.add_run(bold_prefix)
        set_run_font(run, bold=True)
        run = p.add_run(text[len(bold_prefix) :])
        set_run_font(run)
    else:
        run = p.add_run(text)
        set_run_font(run)
    return p


def add_bullet(doc, text):
    p = doc.add_paragraph(style="List Bullet")
    run = p.add_run(text)
    set_run_font(run)
    return p


def add_numbered(doc, text):
    p = doc.add_paragraph(style="List Number")
    run = p.add_run(text)
    set_run_font(run)
    return p


def add_callout(doc, title, body):
    table = doc.add_table(rows=1, cols=1)
    table.alignment = WD_TABLE_ALIGNMENT.CENTER
    set_table_width(table, 9360, 120)
    clear_table_borders(table)
    cell = table.cell(0, 0)
    set_cell_shading(cell, CALLOUT_FILL)
    set_cell_margins(cell, top=150, bottom=150, start=180, end=180)
    p = cell.paragraphs[0]
    run = p.add_run(title)
    set_run_font(run, size=10.5, color=DARK_BLUE, bold=True)
    p = cell.add_paragraph()
    run = p.add_run(body)
    set_run_font(run, size=10.5, color=BLACK)
    doc.add_paragraph()


def add_code_block(doc, code):
    table = doc.add_table(rows=1, cols=1)
    table.alignment = WD_TABLE_ALIGNMENT.CENTER
    set_table_width(table, 9360, 120)
    clear_table_borders(table)
    cell = table.cell(0, 0)
    set_cell_shading(cell, CODE_FILL)
    set_cell_margins(cell, top=120, bottom=120, start=160, end=160)
    p = cell.paragraphs[0]
    p.paragraph_format.space_before = Pt(0)
    p.paragraph_format.space_after = Pt(0)
    run = p.add_run(code)
    set_run_font(run, name="Courier New", size=8.6, color=BLACK)
    doc.add_paragraph()


def add_figure_placeholder(doc, number, caption):
    table = doc.add_table(rows=1, cols=1)
    table.alignment = WD_TABLE_ALIGNMENT.CENTER
    set_table_width(table, 7600, 880)
    set_table_borders(table, color="BFC8D2")
    cell = table.cell(0, 0)
    set_cell_shading(cell, "F7F9FC")
    set_cell_margins(cell, top=260, bottom=260, start=180, end=180)
    p = cell.paragraphs[0]
    p.alignment = WD_ALIGN_PARAGRAPH.CENTER
    run = p.add_run("[Insert screenshot here]")
    set_run_font(run, size=10, color=MUTED, italic=True)

    p = doc.add_paragraph()
    p.alignment = WD_ALIGN_PARAGRAPH.CENTER
    run = p.add_run(f"Figure {number}. {caption}")
    set_run_font(run, size=9.5, color=MUTED, italic=True)


def add_explanation_list(doc, items):
    for item in items:
        add_bullet(doc, item)


def add_table(doc, headers, rows, widths):
    table = doc.add_table(rows=1, cols=len(headers))
    table.alignment = WD_TABLE_ALIGNMENT.CENTER
    set_table_width(table, 9360, 120)
    set_table_borders(table, color="D7DCE2")

    for idx, header in enumerate(headers):
        cell = table.rows[0].cells[idx]
        cell.text = header
        set_cell_shading(cell, LIGHT_FILL)
        set_cell_margins(cell)
        set_cell_width(cell, widths[idx])
        for paragraph in cell.paragraphs:
            for run in paragraph.runs:
                set_run_font(run, size=10, color=DARK_BLUE, bold=True)

    for row_values in rows:
        cells = table.add_row().cells
        for idx, value in enumerate(row_values):
            cells[idx].text = value
            set_cell_margins(cells[idx])
            set_cell_width(cells[idx], widths[idx])
            cells[idx].vertical_alignment = WD_ALIGN_VERTICAL.CENTER
            for paragraph in cells[idx].paragraphs:
                paragraph.paragraph_format.space_after = Pt(0)
                for run in paragraph.runs:
                    set_run_font(run, size=9.7, color=BLACK)
    doc.add_paragraph()
    return table


def build_report():
    doc = Document()
    configure_document(doc)
    add_title_page(doc)
    add_front_matter(doc)

    add_heading(doc, "1. Introduction", 1)
    add_para(
        doc,
        "UniLink is a Flutter mobile application designed to support university club discovery, "
        "club management, event publishing, event registration, student interaction, and realtime communication. "
        "The project uses Firebase Firestore as the main persistence layer and organizes the codebase into screens, "
        "models, services, providers, and reusable widgets. This structure improves maintainability because each class "
        "has a clear responsibility and each feature can be extended without forcing unrelated UI or data logic to change.",
    )
    add_para(
        doc,
        "The report focuses on the three compulsory technical features required for the project: map integration, "
        "multimedia integration, and data persistence. It also explains additional implemented features such as event "
        "dashboards, post interaction, saved posts, club chat rooms, direct messaging, membership requests, privacy controls, "
        "notifications, and manager-side payment or document handling.",
    )

    add_heading(doc, "2. System Overview", 1)
    add_table(
        doc,
        ["Layer", "Main Responsibility", "Examples in the Project"],
        [
            (
                "Screens",
                "Display pages, collect input, and coordinate user actions.",
                "home_screen.dart, club_detail_screen.dart, create_event_screen.dart, event_dashboard_screen.dart",
            ),
            (
                "Widgets",
                "Reusable UI blocks shared across screens.",
                "post_card.dart, event_card.dart, identity_avatar.dart, event_map_preview.dart",
            ),
            (
                "Models",
                "Represent structured app data and convert it to or from Firestore maps.",
                "event.dart, post.dart, club.dart, chat_message.dart, event_registration.dart",
            ),
            (
                "Services",
                "Perform backend operations such as saving, loading, updating, and sending notifications.",
                "event_service.dart, notification_service.dart, direct_chat_service.dart, club_room_service.dart",
            ),
            (
                "Providers",
                "Keep cross-screen application state.",
                "auth_provider.dart, theme_provider.dart, club_follow_provider.dart, notification_provider.dart",
            ),
        ],
        [1600, 3300, 4460],
    )
    add_callout(
        doc,
        "Architecture summary",
        "The app follows a practical separation of concerns. Screens focus on interaction, models define data shape, "
        "services isolate Firestore logic, and widgets keep repeated visual elements consistent across the student and manager interfaces.",
    )

    add_heading(doc, "3. Screenshot Requirements and Figure Captions", 1)
    add_para(
        doc,
        "The following figure captions are prepared for the final report screenshots. Each screenshot should be inserted "
        "above its caption. Together, they cover the app design, compulsory features, and key workflows.",
    )
    captions = [
        "Splash or login screen showing the first entry point of UniLink.",
        "Sign up screen showing account creation and gender profile selection.",
        "Home screen showing upcoming events and recent club posts loaded from Firestore.",
        "Clubs screen showing available clubs and follow status.",
        "Club detail screen showing cover image, logo, follower count, posts, events, members, followers, and photos.",
        "Event detail screen showing event information, registration state, map location, and media gallery.",
        "Map picker screen showing the selected event location on the interactive map.",
        "Post detail screen showing post multimedia, likes, comments, and saved-post actions.",
        "Event registration confirmation dialog showing payment receipt and additional requirement inputs.",
        "Notifications screen showing event, post, room invite, payment, and request notifications loaded from Firestore.",
        "Profile screen showing user information, editable profile image, joined clubs, followed clubs, and request shortcuts.",
        "Settings screen showing privacy, follower visibility, member visibility, message privacy, notification preferences, and feed priority settings.",
        "Saved posts screen showing search and club filtering for saved content.",
        "Direct messages list showing unread indicators for private conversations.",
        "Direct chat screen showing realtime messages and a shared post or event attachment.",
        "Club room chat screen showing member-only room messages and a shared event or post.",
        "Club room dashboard showing rooms, recent speakers, room editing, and event-based invite options.",
        "My Club profile tab showing club logo, cover, about text, photos, and logo background controls.",
        "Manager posts tab showing post cards with edit and delete actions.",
        "Manager events tab showing event cards, event creation, editing, and dashboard entry.",
        "Event dashboard overview showing planned, active, and finished events with filters.",
        "Event registrations dashboard showing attendance, pending requests, accepted students, rejected students, and quick approval actions.",
        "Event payments and documents tab showing registration receipts, required files, and manager review actions.",
        "Members tab showing club members and membership request management.",
        "Club payment dashboard showing monthly fee requests, receipt upload status, and daily or monthly statistics.",
        "Admin dashboard showing system-level clubs and users management.",
    ]
    for idx, caption in enumerate(captions, start=1):
        add_figure_placeholder(doc, idx, caption)

    add_heading(doc, "4. Compulsory Feature 1: Map Integration", 1)
    add_heading(doc, "4.1 What the Feature Does", 2)
    add_para(
        doc,
        "The map feature allows a club manager to select the physical location of an event. The manager opens a map picker, "
        "taps the correct point, confirms the selection, and the event stores the selected latitude and longitude. Students "
        "later see the same saved location in the event detail screen through a compact map preview.",
    )
    add_para(
        doc,
        "The implementation uses the flutter_map package to render map tiles and the latlong2 package to represent coordinates. "
        "The default starting point is XMUM, represented by latitude 2.8329 and longitude 101.7077. This makes the default map view "
        "relevant to the university context instead of using an unrelated external location.",
    )
    add_figure_placeholder(
        doc,
        len(captions) + 1,
        "Compulsory map feature working in the app: event location displayed on the map.",
    )

    add_heading(doc, "4.2 Key Code Snippet", 2)
    add_code_block(
        doc,
        """_selectedLocation =
    widget.initialLocation ?? const LatLng(2.8329, 101.7077);

FlutterMap(
  options: MapOptions(
    initialCenter: _selectedLocation,
    initialZoom: 15,
    onTap: (_, point) => setState(() => _selectedLocation = point),
  ),
  children: [
    TileLayer(
      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
      userAgentPackageName: 'com.example.unilink',
    ),
    MarkerLayer(
      markers: [
        Marker(
          point: _selectedLocation,
          child: Icon(Icons.location_on_rounded, color: cs.primary),
        ),
      ],
    ),
  ],
)""",
    )
    add_heading(doc, "4.3 Line-by-Line Explanation", 2)
    add_explanation_list(
        doc,
        [
            "_selectedLocation stores the currently selected coordinate for the event.",
            "widget.initialLocation lets the edit screen reopen an already saved event location.",
            "const LatLng(2.8329, 101.7077) sets XMUM as the default map location.",
            "FlutterMap creates the interactive map widget.",
            "MapOptions configures the initial center, zoom level, and tap behavior.",
            "initialCenter points the map to the selected coordinate when the screen opens.",
            "initialZoom: 15 gives a close campus-level view that is useful for choosing a venue.",
            "onTap receives the tapped coordinate and stores it in state.",
            "setState refreshes the UI so the marker moves immediately after the tap.",
            "TileLayer loads OpenStreetMap tiles through the flutter_map renderer.",
            "userAgentPackageName identifies the app when requesting tiles.",
            "MarkerLayer displays markers over the map.",
            "Marker(point: _selectedLocation) keeps the visual pin synchronized with the selected coordinate.",
            "The location icon uses the current theme color so the map marker stays consistent in light and dark mode.",
        ],
    )

    add_heading(doc, "4.4 Saving and Displaying the Map Location", 2)
    add_code_block(
        doc,
        """final picked = await Navigator.push<LatLng>(
  context,
  MaterialPageRoute(
    builder: (_) => EventLocationPickerScreen(
      initialLocation: _selectedMapLocation,
    ),
  ),
);
if (picked != null) setState(() => _selectedMapLocation = picked);

latitude: _selectedMapLocation?.latitude,
longitude: _selectedMapLocation?.longitude,""",
    )
    add_explanation_list(
        doc,
        [
            "Navigator.push opens the dedicated map picker screen and waits for a LatLng result.",
            "initialLocation passes the existing coordinate into the picker when an event is edited.",
            "Navigator.pop in the picker returns the selected coordinate after the manager presses Use.",
            "The null check protects the form when the manager exits without selecting a point.",
            "The selected latitude and longitude are assigned to the EventModel before saving.",
            "The event detail screen later reads these values and passes them to EventMapPreview for display.",
        ],
    )

    add_heading(doc, "5. Compulsory Feature 2: Multimedia Integration", 1)
    add_heading(doc, "5.1 What the Feature Does", 2)
    add_para(
        doc,
        "UniLink supports multimedia by allowing clubs to attach images to posts, events, room icons, club logos, club covers, "
        "club photo galleries, profile photos, payment receipts, and registration requirement files. The interface lets users "
        "preview these images and tap many of them to open a larger view, which is useful for event posters and activity photos.",
    )
    add_para(
        doc,
        "For this project version, Firebase Storage is intentionally not used. Instead, selected images are compressed, read as bytes, "
        "converted to Base64 strings, and stored in Firestore fields. This approach is simple for a prototype and keeps the backend setup "
        "limited to Firestore. A production version should move large media files to Firebase Storage to reduce document size.",
    )
    add_figure_placeholder(
        doc,
        len(captions) + 2,
        "Compulsory multimedia feature working in the app: image selected, previewed, saved, and displayed.",
    )

    add_heading(doc, "5.2 Key Code Snippet", 2)
    add_code_block(
        doc,
        """Future<void> _pickCover() async {
  final file = await _picker.pickImage(
    source: ImageSource.gallery,
    maxWidth: 900,
    imageQuality: 70,
  );
  if (file == null) return;
  final bytes = await file.readAsBytes();
  setState(() => _coverImage = bytes);
}

final coverImageBase64 =
    _coverImage == null ? null : base64Encode(_coverImage!);
final photoBase64List =
    _additionalImages.map((bytes) => base64Encode(bytes)).toList();""",
    )
    add_heading(doc, "5.3 Line-by-Line Explanation", 2)
    add_explanation_list(
        doc,
        [
            "_pickCover is an asynchronous method because opening the gallery and reading a file are non-blocking operations.",
            "_picker.pickImage opens the device image picker.",
            "ImageSource.gallery specifies that the image should come from the phone gallery.",
            "maxWidth: 900 reduces very large images before saving, improving mobile performance.",
            "imageQuality: 70 compresses the image to reduce the amount of text stored in Firestore.",
            "if (file == null) return handles the case where the user cancels the picker.",
            "file.readAsBytes reads the selected image as binary data.",
            "setState stores the selected bytes and refreshes the preview on screen.",
            "coverImageBase64 converts the selected cover image into a Firestore-safe string.",
            "The null check keeps the cover optional when the manager does not select an image.",
            "photoBase64List converts each additional image into Base64 for storage.",
            "The saved strings are decoded later by reusable image widgets such as Base64Image and IdentityAvatar.",
        ],
    )

    add_heading(doc, "5.4 Multimedia UI Behavior", 2)
    add_para(
        doc,
        "The UI separates the cover image from the additional gallery images. This gives the manager a clear primary poster area and "
        "a secondary gallery area. The same pattern is used for club cover images, club logos, and room images. The app also avoids "
        "relying on text initials for avatars; when a profile photo is missing, the gender icon is used consistently across the app.",
    )
    add_para(
        doc,
        "Images are treated as optional. If a club, profile, post, or event does not have an uploaded image, the UI falls back to a "
        "theme-aware icon, color, or placeholder. This prevents broken image views and keeps light and dark modes visually consistent.",
    )

    add_heading(doc, "6. Compulsory Feature 3: Data Persistence", 1)
    add_heading(doc, "6.1 What the Feature Does", 2)
    add_para(
        doc,
        "Data persistence means that the app stores information permanently instead of losing it when the screen changes or the app closes. "
        "UniLink persists clubs, profiles, posts, comments, saved posts, events, registrations, event analytics, notifications, room messages, "
        "direct messages, payment requests, and membership requests in Firebase Firestore.",
    )
    add_para(
        doc,
        "The project uses model classes to convert typed Dart objects into Firestore maps. Services then save and load those maps. This keeps "
        "Firestore code out of the UI and makes the app easier to maintain.",
    )
    add_figure_placeholder(
        doc,
        len(captions) + 3,
        "Compulsory data persistence feature working in the app: data saved to Firestore and loaded back in the UI.",
    )

    add_heading(doc, "6.2 Event Save and Load Code", 2)
    add_code_block(
        doc,
        """Future<void> saveEvent(EventModel event) =>
    _events.doc(event.id).set(event.toMap());

Future<EventModel?> getEventById(String id, {String? userId}) async {
  final doc = await _events.doc(id).get();
  if (!doc.exists) return null;
  final event = EventModel.fromMap(doc.data()!);
  final events = await _withRegistrationState([event], userId);
  return events.isEmpty ? event : events.first;
}""",
    )
    add_heading(doc, "6.3 Line-by-Line Explanation", 2)
    add_explanation_list(
        doc,
        [
            "saveEvent receives a typed EventModel object from the event form.",
            "_events.doc(event.id) selects the Firestore document that belongs to that event.",
            "set(event.toMap()) converts the EventModel into a Map and writes it to Firestore.",
            "getEventById loads a single event document by its id.",
            "await _events.doc(id).get() performs the Firestore read operation asynchronously.",
            "if (!doc.exists) return null safely handles missing or deleted documents.",
            "EventModel.fromMap converts raw Firestore data back into a strongly typed Dart object.",
            "_withRegistrationState enriches the event with the current user's registration status.",
            "The final return statement gives the UI either the enriched event or the basic loaded event.",
        ],
    )

    add_heading(doc, "6.4 Firestore Transactions and Atomic Counters", 2)
    add_code_block(
        doc,
        """await _db.runTransaction((tx) async {
  final eventRef = _events.doc(event.id);
  final eventDoc = await tx.get(eventRef);
  if (!eventDoc.exists) {
    throw Exception('Event not found.');
  }

  final regRef = _registrations.doc(registrationId);
  final regDoc = await tx.get(regRef);
  if (!regDoc.exists) {
    _ensureCapacity(eventDoc.data()!);
    tx.set(regRef, registration.toMap());
    tx.update(eventRef, {
      'registeredCount': FieldValue.increment(1),
    });
  }
});""",
    )
    add_explanation_list(
        doc,
        [
            "runTransaction groups multiple Firestore operations into one safe operation.",
            "eventRef points to the event document that will receive the registration count update.",
            "tx.get(eventRef) reads the latest event data inside the transaction.",
            "The missing-event check prevents registering for a deleted event.",
            "regRef points to the current user's registration document for this event.",
            "tx.get(regRef) checks whether the student already has a registration record.",
            "_ensureCapacity validates the event limit before adding a new registration.",
            "tx.set(regRef, registration.toMap()) saves the registration document.",
            "FieldValue.increment(1) updates the event counter atomically so concurrent registrations do not overwrite each other.",
        ],
    )

    add_heading(doc, "7. Additional Implemented Features", 1)
    add_table(
        doc,
        ["Feature", "Purpose", "Implementation Summary"],
        [
            (
                "Event dashboard",
                "Allows managers to monitor registrations, attendance, pending requests, payments, and documents.",
                "Event services load analytics, registration records, and status counts from Firestore.",
            ),
            (
                "Post interaction",
                "Allows students to like, comment, edit their own comments, delete their own comments, and lets club owners moderate comments.",
                "Likes use arrayUnion/arrayRemove and comment counts use Firestore increments.",
            ),
            (
                "Saved posts",
                "Allows students to save posts and later search or filter saved content by club.",
                "Saved post documents link the user id, post id, club id, and saved timestamp.",
            ),
            (
                "Club rooms",
                "Provides member-only text rooms for each club with room settings and guest invitations.",
                "Rooms and messages are stored under club_rooms, and messages stream in realtime.",
            ),
            (
                "Direct messages",
                "Supports person-to-person realtime chat with unread indicators and shareable post/event attachments.",
                "Chats are stored in direct_chats and ordered by updated_at.",
            ),
            (
                "Membership requests",
                "Allows non-members to request club membership and lets managers approve, reject, or request payment evidence.",
                "Requests are stored separately from followers so membership and following remain different concepts.",
            ),
            (
                "Notifications",
                "Routes event, post, room invite, payment, registration, and message updates back to the correct user.",
                "Notification documents include a type and reference id so screens can navigate to the related item.",
            ),
        ],
        [1850, 3100, 4410],
    )

    add_heading(doc, "8. Analysis of Related Programming Concepts", 1)
    concepts = [
        (
            "Separation of concerns",
            "The app separates screens, widgets, models, services, and providers. This reduces coupling because UI classes do not need to know all Firestore details, and backend services do not need to know visual layout details.",
        ),
        (
            "Object modeling",
            "Models such as EventModel, ClubModel, PostModel, and ChatMessage define the data shape used across the app. The toMap and fromMap methods provide a consistent bridge between typed Dart objects and Firestore documents.",
        ),
        (
            "Asynchronous programming",
            "Firebase reads, writes, image picking, and navigation results are asynchronous. The app uses async and await to keep the UI responsive while waiting for external operations.",
        ),
        (
            "State management",
            "Provider stores shared state such as authentication, theme mode, notifications, and followed clubs. StatefulWidget state is used for temporary form values such as selected images, selected dates, and selected map coordinates.",
        ),
        (
            "Realtime streams",
            "Chat rooms, direct messages, comments, and some notification interfaces can listen to Firestore snapshots. When Firestore changes, the UI receives the new data and rebuilds automatically.",
        ),
        (
            "Transactions",
            "Event registration uses Firestore transactions to update both the registration document and event counters safely. This protects the app from race conditions when multiple students register at the same time.",
        ),
        (
            "Role-based behavior",
            "The app distinguishes between students, club managers, members, followers, and administrators. This affects what dashboards, moderation actions, rooms, and member data each user can access.",
        ),
        (
            "Validation",
            "The app validates required form data, event dates, payment amounts, capacity limits, URLs, and optional registration requirements before saving or submitting data.",
        ),
        (
            "Responsive mobile UI",
            "Cards, lists, and forms use flexible constraints, wrapping text, and scrollable layouts so content can adapt to different phone sizes without pixel overflow.",
        ),
        (
            "Privacy settings",
            "The profile settings allow users to control whether they appear in member or follower lists and whether all students or only club members can message them.",
        ),
    ]
    for title, body in concepts:
        p = doc.add_paragraph()
        label = p.add_run(f"{title}: ")
        set_run_font(label, bold=True, color=DARK_BLUE)
        run = p.add_run(body)
        set_run_font(run)

    add_heading(doc, "9. Data Collections and Persistence Design", 1)
    add_table(
        doc,
        ["Collection", "Stores", "Example Use"],
        [
            ("profiles", "User profile, role, gender, privacy settings, photos", "Profile screen, identity avatars, settings"),
            ("clubs", "Club name, about text, logo, cover, photos, manager data", "Club list, club details, My Club profile"),
            ("posts", "Club posts, media, likes, saved counts, comment counts", "Home feed, post details, saved posts"),
            ("events", "Event details, map coordinates, fees, limits, requirements, counters", "Home carousel, event detail, event dashboard"),
            ("event_registrations", "Student registrations, payment receipts, requirement responses, status, attendance", "Registration review and attendance tracking"),
            ("notifications", "User-facing alerts with type and reference id", "Navigation to events, posts, rooms, chats, and payment requests"),
            ("club_rooms", "Club text rooms, guests, room images, room messages", "Club room chat and room settings"),
            ("direct_chats", "Private chats, unread counts, message attachments", "Direct messages list and direct chat screen"),
            ("user_follows", "Student follows for clubs", "Follower count, follower list, feed priority"),
            ("saved_posts", "User saved post references", "Saved posts search and club filtering"),
        ],
        [2100, 4000, 3260],
    )

    add_heading(doc, "10. Evaluation Against Requirements", 1)
    add_table(
        doc,
        ["Requirement", "How UniLink Meets It"],
        [
            (
                "Map integration",
                "Managers select event locations using flutter_map and latlong2; students view the saved coordinates in event details.",
            ),
            (
                "Multimedia integration",
                "Posts, events, clubs, profiles, rooms, receipts, and registration files support image upload, preview, and display.",
            ),
            (
                "Data persistence",
                "Firestore stores all major data models and reloads them across app sessions and devices.",
            ),
            (
                "Screenshots",
                "The report includes figure placeholders and captions for all important app screens and the three compulsory features.",
            ),
            (
                "Technical explanation",
                "Each compulsory feature includes code snippets and line-by-line explanation.",
            ),
            (
                "Maintainability",
                "Each feature is separated into focused classes, widgets, models, services, and providers.",
            ),
        ],
        [2500, 6860],
    )

    add_heading(doc, "11. Limitations and Future Improvements", 1)
    add_bullet(
        doc,
        "Firebase Storage is not used in this version, so images are stored as Base64 strings in Firestore. This is acceptable for the current prototype but should be replaced with Firebase Storage for large-scale media.",
    )
    add_bullet(
        doc,
        "Video integration is not enabled in the current submitted scope. It can be added later with a video picker, video compression, Firebase Storage, and a Firestore metadata document.",
    )
    add_bullet(
        doc,
        "Voice rooms are not included in the current scope. A future implementation would require a realtime audio provider, permission handling, moderation controls, and session state management.",
    )
    add_bullet(
        doc,
        "Push notifications can be improved with Firebase Cloud Messaging so users receive alerts even when the app is closed.",
    )

    add_heading(doc, "12. Conclusion", 1)
    add_para(
        doc,
        "UniLink implements the required mobile application features in a structured and maintainable way. The map feature connects events "
        "to real physical locations, the multimedia feature makes posts and events visually informative, and the Firestore persistence layer "
        "keeps user, club, post, event, registration, notification, and chat data available across sessions. Additional features such as event "
        "dashboards, comment moderation, saved posts, club rooms, direct messages, membership requests, and privacy settings strengthen the app "
        "as a complete university club platform.",
    )

    doc.save(DOCX_PATH)
    TEXT_PATH.write_text(build_markdown_text(), encoding="utf-8")


def build_markdown_text():
    return """# UniLink Mobile Application Report

## Scope

This formal report documents UniLink, a Flutter mobile application for university clubs. It explains the three compulsory features: Map Integration, Multimedia Integration, and Data Persistence. It also includes figure captions for screenshots and an analysis of related programming concepts.

## Required Figure Captions

1. Splash or login screen showing the first entry point of UniLink.
2. Sign up screen showing account creation and gender profile selection.
3. Home screen showing upcoming events and recent club posts loaded from Firestore.
4. Clubs screen showing available clubs and follow status.
5. Club detail screen showing cover image, logo, follower count, posts, events, members, followers, and photos.
6. Event detail screen showing event information, registration state, map location, and media gallery.
7. Map picker screen showing the selected event location on the interactive map.
8. Post detail screen showing post multimedia, likes, comments, and saved-post actions.
9. Event registration confirmation dialog showing payment receipt and additional requirement inputs.
10. Notifications screen showing event, post, room invite, payment, and request notifications loaded from Firestore.
11. Profile screen showing user information, editable profile image, joined clubs, followed clubs, and request shortcuts.
12. Settings screen showing privacy, follower visibility, member visibility, message privacy, notification preferences, and feed priority settings.
13. Saved posts screen showing search and club filtering for saved content.
14. Direct messages list showing unread indicators for private conversations.
15. Direct chat screen showing realtime messages and a shared post or event attachment.
16. Club room chat screen showing member-only room messages and a shared event or post.
17. Club room dashboard showing rooms, recent speakers, room editing, and event-based invite options.
18. My Club profile tab showing club logo, cover, about text, photos, and logo background controls.
19. Manager posts tab showing post cards with edit and delete actions.
20. Manager events tab showing event cards, event creation, editing, and dashboard entry.
21. Event dashboard overview showing planned, active, and finished events with filters.
22. Event registrations dashboard showing attendance, pending requests, accepted students, rejected students, and quick approval actions.
23. Event payments and documents tab showing registration receipts, required files, and manager review actions.
24. Members tab showing club members and membership request management.
25. Club payment dashboard showing monthly fee requests, receipt upload status, and daily or monthly statistics.
26. Admin dashboard showing system-level clubs and users management.
27. Compulsory map feature working in the app: event location displayed on the map.
28. Compulsory multimedia feature working in the app: image selected, previewed, saved, and displayed.
29. Compulsory data persistence feature working in the app: data saved to Firestore and loaded back in the UI.

## Feature 1: Map Integration

The app uses `flutter_map` and `latlong2` to let club managers choose event locations. The default coordinate is XMUM: latitude 2.8329 and longitude 101.7077. When the manager taps the map, the selected coordinate is stored in state. When the event is saved, the latitude and longitude are written to Firestore and later displayed in the event detail screen.

## Feature 2: Multimedia Integration

The app supports image upload for posts, events, clubs, profiles, rooms, receipts, and registration requirement files. Images are picked from the device gallery, compressed, read as bytes, converted to Base64, and saved in Firestore. The UI decodes the saved Base64 strings and displays images in cards, details, galleries, and avatars.

## Feature 3: Data Persistence

Firebase Firestore stores profiles, clubs, posts, events, event registrations, notifications, club rooms, direct chats, follows, and saved posts. Model classes convert typed Dart objects to maps before saving and convert Firestore data back into Dart objects when loading. Transactions are used for event registration counters so capacity checks and counter increments remain consistent.

## Related Programming Concepts

- Separation of concerns: screens, widgets, models, services, and providers have different responsibilities.
- Object modeling: model classes define the structure of app data.
- Asynchronous programming: Firebase and image operations use async and await.
- State management: Provider stores shared app state while StatefulWidget state handles local form values.
- Realtime streams: chats, comments, and notifications update through Firestore snapshots.
- Transactions: event registration uses atomic updates for counters and capacity.
- Role-based behavior: students, managers, members, followers, and admins see different actions.
- Validation: forms check dates, URLs, fees, capacity, and required registration information.
- Responsive UI: cards and layouts use flexible constraints to avoid overflow on different devices.
"""


if __name__ == "__main__":
    build_report()
    print(DOCX_PATH)
    print(TEXT_PATH)
