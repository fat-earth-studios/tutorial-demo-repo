# Fat Earth Studios - Godot Tutorial Project

This repository contains the public companion project for the Godot development tutorials on [**Fat Earth Studios**](https://www.youtube.com/@FatEarthStudios).

The project is updated alongside the video series so that you can explore the scripts, project structure, and examples shown in each tutorial.

The default branch contains the latest public version of the project.
For the version shown in a specific video, use the corresponding repository tag listed below.

## Tutorial Videos and Project Snapshots

| Tutorial                              | Video                                                                         | Project Version                                                      |
| ------------------------------------- | ----------------------------------------------------------------------------- | -------------------------------------------------------------------- |
| Git and GitHub Workflow for Godot     | [How To Use Git With Godot](https://youtu.be/9yfNX0OdSAw?si=Zy0y8DdWJb68yOdq) | [View the Git tutorial snapshot](https://github.com/fat-earth-studios/tutorial-demo-repo/tree/video-0-git-tutorial) |
| Setting Up a Godot Project Foundation | [Godot Project Foundation Setup](https://youtu.be/V4SO7foDoW4)                | [View the Project Foundation tutorial snapshot](https://github.com/fat-earth-studios/tutorial-demo-repo/tree/video-1-project-foundation)                                 |

Each tagged snapshot preserves the state of the repository associated with that tutorial, while the default branch continues to receive the additions shown in future videos.

## Included Guides

### Git Cheat Sheet

A practical reference for the Git commands and workflows covered in the Git tutorial:

* [Git Cheat Sheet](./docs/Git_Cheat_Sheet_Godot.md)

## Project Structure

The Godot project is located in:

[`main-game-setup-tutorial/`](./main-game-setup-tutorial/)


```text
main-game-setup-tutorial/
  addons/             Third-party Godot add-ons
  assets/             Art, audio, fonts, shaders, and other game assets
  src/
    core/             Foundational scenes and scripts
      autoload/       Globally available systems
      main_game/      Main entry point for the game
    debug/            Development and debugging tools
    gameplay/         Gameplay-specific code
    levels/           Level scenes and related scripts
    resources/        Reusable data and resource definitions
    shaders/          Shaders used for visual effects
    ui/               User interface scenes and scripts
  project.godot
```

The exact contents will expand as new tutorials are released.

## Requirements

This project was created using **Godot 4.6.3**.

Opening the project with **Godot 4.6.3 or newer** is recommended.
Older versions of Godot 4.x may not open the project correctly.

To clone and open the full project, you will need:

* Godot 4.6.3 or newer
* Git
* Git LFS

## Downloading the Project

You can clone the repository using SSH or HTTPS.

### SSH

```bash
git clone git@github.com:fat-earth-studios/tutorial-demo-repo.git
```

### HTTPS

```bash
git clone https://github.com/fat-earth-studios/tutorial-demo-repo.git
```

After cloning, open the following file in Godot:

```text
main-game-setup-tutorial/project.godot
```

If Git LFS files were not downloaded automatically, run:

```bash
git lfs pull
```


## Using an Earlier Tutorial Snapshot

The default branch changes as new videos are released. If you want to inspect the project exactly as it appeared during an earlier tutorial, check out the matching tag.

For example:

```bash
git tag
git checkout video-0-git-tutorial
```

To return to the current version afterward:

```bash
git checkout master
```


## License

### Code

The source code in this repository is licensed under the MIT License.

See the [LICENSE](./LICENSE) file for details.

### Artwork and Assets

Artwork, music, sound, and other non-code assets are not included under the MIT License and remain the property of Daniel B. Russell.

You are welcome to download the repository and explore the project for personal learning and evaluation purposes. However, those assets may not be copied, redistributed, or reused in other projects without prior written permission.

If you would like to feature the project, use its assets, or discuss another use case, please contact me.

See [ASSETS_LICENSE.md](./ASSETS_LICENSE.md) for details.

## Community and Support

Have a question, want to discuss the tutorials, or want to share what you're building?

* Join the [Fat Earth Studios Discord](https://discord.gg/cBxW2j2Gb5)
* Watch more tutorials on the [Fat Earth Studios YouTube channel](https://www.youtube.com/@FatEarthStudios)

If the tutorials or public resources have helped you and you would like to support their development, you can also visit the [Fat Earth Studios Ko-fi page](https://ko-fi.com/fatearthstudios).

## About Fat Earth Studios

This repository is part of my game development and tutorial work under **Fat Earth Studios**.

The channel covers Godot development, game architecture, practical workflows, debugging, performance, and the small decisions that help a prototype grow into a maintainable game project.
