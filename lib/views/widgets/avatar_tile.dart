import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:learn_with_ar/modals/avatar.dart';
import 'package:learn_with_ar/views/description_screen.dart';

class AvatarTile extends StatefulWidget {
  Avatar currentAvatar;
  AvatarTile({this.currentAvatar});
  @override
  _AvatarTileState createState() => _AvatarTileState();
}

class _AvatarTileState extends State<AvatarTile> {
  @override
  Widget build(BuildContext context) {
    double h = MediaQuery.of(context).size.height;
    double w = MediaQuery.of(context).size.width;

    return Material(
      elevation: 3,
      borderRadius: BorderRadius.circular(15),
      child: GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => DescriptionScreen(
                currentAvatar: widget.currentAvatar,
              ),
            ),
          );
        },
        child: Container(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(15),
                child: Container(
                  height: h * 0.2,
                  width: double.infinity,
                  child: Image.network(
                    widget.currentAvatar.imageUrl,
                    fit: BoxFit.cover,
                    loadingBuilder: (BuildContext context, Widget child,
                        ImageChunkEvent loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Container(
                        height: h * 0.2,
                        child: Center(
                          child: CircularProgressIndicator(
                            value: loadingProgress.expectedTotalBytes != null
                                ? loadingProgress.cumulativeBytesLoaded /
                                    loadingProgress.expectedTotalBytes
                                : null,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              Spacer(),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Container(
                    width: w*0.25,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.currentAvatar.name,
                          style: Theme.of(context)
                              .textTheme
                              .bodyText1
                              .copyWith(fontSize: 13),
                        ),
                        Text(
                          widget.currentAvatar.type,
                          style: Theme.of(context).textTheme.bodyText1.copyWith(fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => DescriptionScreen(
                            currentAvatar: widget.currentAvatar,
                          ),
                        ),
                      );
                    },
                    child: Material(
                      elevation: 4,
                      borderRadius: BorderRadius.circular(10),
                      color: Colors.deepPurple,
                      child: Container(
                        child: Padding(
                          padding: const EdgeInsets.all(10.0),
                          child: Text(
                            'View AR',
                            style:
                                Theme.of(context).textTheme.bodyText1.copyWith(
                                      color: Colors.white,
                                    ),
                          ),
                        ),
                        decoration: BoxDecoration(
                          color: Colors.deepPurple,
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  )
                ],
              ),
              SizedBox(
                height: h * 0.02,
              )
            ],
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15),
          ),
        ),
      ),
    );
  }
}
